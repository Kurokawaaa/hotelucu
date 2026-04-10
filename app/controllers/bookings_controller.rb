class BookingsController < ApplicationController
  class BookingCreationError < StandardError; end

  before_action :authenticate_user!

  def index
    @bookings = current_user.bookings.includes(room: :room_level)
  end

  def new
    @booking = Booking.new
    @room_levels = RoomLevel.all
    @selected_room_level_id = selected_room_level_id
    @booking_items = default_booking_items
  end

  def create
    check_in = parse_booking_date(params.dig(:booking, :check_in))
    check_out = parse_booking_date(params.dig(:booking, :check_out))
    items = booking_items
    booking_code = nil

    if check_in.blank? || check_out.blank?
      handle_invalid_booking(
        check_in:,
        check_out:,
        items: items,
        message: "Tanggal check-in dan check-out wajib diisi"
      )
      return
    end

    if check_out <= check_in
      handle_invalid_booking(
        check_in:,
        check_out:,
        items: items,
        message: "Tanggal check-out harus setelah check-in"
      )
      return
    end

    if items.empty?
      handle_invalid_booking(
        check_in:,
        check_out:,
        items: items,
        message: "Pilih minimal 1 tingkatan kamar"
      )
      return
    end

    room_level_ids = items.map { |item| item[:room_level_id] }
    room_level_map = RoomLevel.where(id: room_level_ids).index_by { |room_level| room_level.id.to_s }
    nights = calculate_nights(check_in, check_out)

    booking_code = Booking.generate_shared_booking_code
    created_bookings = []

    Booking.transaction do
      booked_room_ids = []

      items.each do |item|
        room_level = room_level_map[item[:room_level_id]]
        quantity = item[:quantity]

        raise BookingCreationError, "Tingkatan kamar tidak valid" unless room_level

        unavailable_room_ids = Booking.unavailable_room_ids(check_in:, check_out:)
        available_rooms = Room.where(room_level_id: room_level.id)
                              .where.not(id: unavailable_room_ids)
                              .lock
                              .limit(quantity)

        if available_rooms.size < quantity
          raise BookingCreationError,
                "Booking bentrok dengan user lain pada tanggal tersebut. Kamar tersedia untuk #{room_level.name} hanya #{available_rooms.size}"
        end

        available_rooms.each do |room|
          status = Booking.status_for_stay(check_in:, check_out:)

          created_bookings << current_user.bookings.create!(
            room: room,
            check_in: check_in,
            check_out: check_out,
            status: status,
            payment_status: "pending",
            booking_code: booking_code
          )

          booked_room_ids << room.id
        end
      end

      Booking.sync_room_statuses!(booked_room_ids.uniq)
    end

    total_amount = calculate_total_amount(items:, room_level_map:, nights:)
    item_details = build_item_details(items:, room_level_map:, nights:)

    midtrans_response = MidtransSnapService.create_transaction!(
      booking_code: booking_code,
      gross_amount: total_amount,
      customer: {
        first_name: current_user.username,
        email: current_user.email
      },
      item_details: item_details
    )

    Booking.where(booking_code: booking_code).update_all(midtrans_snap_token: midtrans_response["token"])

    first_booking = created_bookings.first

    respond_to do |format|
      format.html { redirect_to booking_path(first_booking), notice: "Booking berhasil dibuat. Silakan lanjutkan pembayaran." }
      format.json do
        render json: {
          snap_token: midtrans_response["token"],
          redirect_url: midtrans_response["redirect_url"],
          booking_code: booking_code,
          booking_id: first_booking.id,
          show_url: booking_url(first_booking)
        }
      end
    end
  rescue MidtransSnapService::Error => e
    if booking_code.present?
      Booking.where(booking_code: booking_code).update_all(status: "expired", payment_status: "failed")
      Booking.sync_room_statuses!
    end

    handle_invalid_booking(
      check_in:,
      check_out:,
      items: items,
      message: "Gagal membuat transaksi Midtrans: #{e.message}"
    )
  rescue BookingCreationError, ActiveRecord::RecordInvalid => e
    handle_invalid_booking(check_in:, check_out:, items: items, message: e.message.presence || "Booking gagal")
  end

  def show
    @booking = current_user.bookings.includes(room: :room_level).find(params[:id])
    sync_payment_status_for(@booking)
    @booking.reload
  end

  def snap_token
    booking = current_user.bookings.includes(room: :room_level).find(params[:id])
    related_bookings = current_user.bookings.includes(room: :room_level).where(booking_code: booking.booking_code)
    sync_payment_status_for(booking)
    booking.reload

    if booking.payment_paid?
      render json: { error: "Pembayaran booking ini sudah lunas.", show_url: booking_url(booking) }, status: :unprocessable_entity
      return
    end

    if booking.expired? || booking.payment_expired?
      render json: { error: "Booking sudah dibatalkan karena melewati batas pembayaran 10 menit.", show_url: booking_url(booking) }, status: :unprocessable_entity
      return
    end

    existing_token = related_bookings.pick(:midtrans_snap_token)
    if existing_token.present?
      render json: { snap_token: existing_token, show_url: booking_url(booking) }
      return
    end

    check_in = booking.check_in
    check_out = booking.check_out
    nights = calculate_nights(check_in, check_out)

    midtrans_response = MidtransSnapService.create_transaction!(
      booking_code: booking.booking_code,
      gross_amount: total_amount_for_bookings(related_bookings),
      customer: {
        first_name: current_user.username,
        email: current_user.email
      },
      item_details: item_details_for_bookings(related_bookings, nights:)
    )

    related_bookings.update_all(midtrans_snap_token: midtrans_response["token"])

    render json: {
      snap_token: midtrans_response["token"],
      redirect_url: midtrans_response["redirect_url"],
      show_url: booking_url(booking)
    }
  rescue MidtransSnapService::Error => e
    if booking.present?
      sync_payment_status_for(booking)
      booking.reload
      if booking.payment_paid?
        render json: { error: "Pembayaran booking ini sudah lunas.", show_url: booking_url(booking) }, status: :unprocessable_entity
        return
      end
    end

    render json: { error: "Gagal membuat token Midtrans: #{e.message}" }, status: :unprocessable_entity
  end

  def confirm_payment
    booking = current_user.bookings.find(params[:id])
    client_payload = normalize_midtrans_payload(payment_callback_payload)

    if client_payload["order_id"].present? && client_payload["order_id"] != booking.booking_code
      render json: { error: "Order ID tidak cocok dengan booking." }, status: :unprocessable_entity
      return
    end

    payload = normalize_midtrans_payload(fetch_midtrans_status(booking.booking_code))
    payload = client_payload if payload.blank?
    apply_midtrans_status_to_bookings(booking.booking_code, payload) if payload.present?

    booking.reload
    render json: { payment_status: booking.payment_status, status: booking.status }
  end

  private

  def booking_items
    Array(params.dig(:booking, :items)).filter_map do |item|
      room_level_id = item[:room_level_id].to_s
      quantity = item[:quantity].to_i
      next if room_level_id.blank? || quantity <= 0

      { room_level_id: room_level_id, quantity: quantity }
    end
  end

  def handle_invalid_booking(check_in:, check_out:, items:, message:)
    @booking = Booking.new(check_in: check_in, check_out: check_out)
    @room_levels = RoomLevel.all
    @selected_room_level_id = selected_room_level_id
    @booking_items = items.presence || default_booking_items

    respond_to do |format|
      format.html do
        flash.now[:alert] = message
        render :new, status: :unprocessable_entity
      end
      format.json { render json: { error: message }, status: :unprocessable_entity }
    end
  end

  def selected_room_level_id
    room_level_param = params[:room_level].to_s.strip
    return if room_level_param.blank?

    RoomLevel.where("LOWER(name) = ?", room_level_param.downcase).pick(:id)
  end

  def parse_booking_date(value)
    return if value.blank?

    Date.parse(value)
  rescue ArgumentError
    nil
  end

  def default_booking_items
    [ { room_level_id: @selected_room_level_id.to_s, quantity: 1 } ]
  end

  def calculate_total_amount(items:, room_level_map:, nights:)
    items.sum do |item|
      room_level = room_level_map[item[:room_level_id]]
      room_level.price * item[:quantity].to_i * nights
    end
  end

  def build_item_details(items:, room_level_map:, nights:)
    items.map.with_index do |item, index|
      room_level = room_level_map[item[:room_level_id]]

      {
        id: "room-level-#{room_level.id}-#{index}",
        price: room_level.price,
        quantity: item[:quantity].to_i * nights,
        name: "#{room_level.name} (per malam)"
      }
    end
  end

  def total_amount_for_bookings(bookings)
    bookings.sum do |entry|
      nights = calculate_nights(entry.check_in, entry.check_out)
      entry.room.room_level.price * nights
    end
  end

  def item_details_for_bookings(bookings, nights:)
    grouped = bookings.group_by { |entry| entry.room.room_level }

    grouped.map.with_index do |(room_level, grouped_bookings), index|
      {
        id: "room-level-#{room_level.id}-#{index}",
        price: room_level.price,
        quantity: grouped_bookings.size * nights,
        name: "#{room_level.name} (per malam)"
      }
    end
  end

  def calculate_nights(check_in, check_out)
    nights = (check_out - check_in).to_i
    nights.positive? ? nights : 1
  end

  def sync_payment_status_for(booking)
    return unless booking.payment_pending?

    if booking.payment_timeout_reached?
      expire_booking_payment_timeout!(booking.booking_code)
      return
    end

    payload = fetch_midtrans_status(booking.booking_code)
    payload = normalize_midtrans_payload(payload)
    return if payload.blank?

    apply_midtrans_status_to_bookings(booking.booking_code, payload)
  end

  def fetch_midtrans_status(booking_code)
    MidtransSnapService.transaction_status(order_id: booking_code)
  rescue MidtransSnapService::Error
    nil
  end

  def payment_callback_payload
    params.permit(:order_id, :transaction_status, :fraud_status, :payment_type, :status_code, :gross_amount).to_h
  end

  def normalize_midtrans_payload(payload)
    return {} if payload.blank?

    normalized = payload.respond_to?(:to_h) ? payload.to_h : payload
    normalized.stringify_keys
  end

  def apply_midtrans_status_to_bookings(booking_code, payload)
    return if payload.blank?

    bookings = Booking.where(booking_code: booking_code)
    return if bookings.blank?

    if bookings.payment_pending.where("created_at <= ?", Time.current - Booking::PAYMENT_TIMEOUT_MINUTES.minutes).exists?
      expire_booking_payment_timeout!(booking_code)
      return
    end

    transaction_status = payload["transaction_status"].to_s
    fraud_status = payload["fraud_status"]
    status_code = payload["status_code"].to_s

    if transaction_status.blank? && status_code == "200"
      transaction_status = "settlement"
    end

    case transaction_status
    when "capture"
      if fraud_status == "challenge"
        bookings.update_all(payment_status: "pending", status: "pending")
      else
        bookings.update_all(payment_status: "paid", status: "paid")
      end
    when "settlement", "success"
      bookings.update_all(payment_status: "paid", status: "paid")
    when "pending"
      bookings.update_all(payment_status: "pending", status: "pending")
    when "deny", "cancel", "expire", "failure"
      bookings.update_all(payment_status: "failed", status: "expired")
    end

    Booking.sync_room_statuses!(bookings.pluck(:room_id))
  end

  def expire_booking_payment_timeout!(booking_code)
    bookings = Booking.where(booking_code: booking_code)
    room_ids = bookings.pluck(:room_id)

    Booking.expire_payment_timeout!(bookings)
    Booking.sync_room_statuses!(room_ids)
  end
end
