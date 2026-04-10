class Admin::BookingsController < Admin::BaseController
  class ReservationCreationError < StandardError; end

  before_action :set_booking, only: [:show, :validate, :checkout, :update, :destroy]
  before_action :load_booking_history_filters, only: :history
  before_action :ensure_resepsionis!, only: [:new_reservation, :create_reservation]

  def index
    today = Date.current

    @paid_bookings = Booking.includes(:user, room: :room_level)
                            .where(status: "paid")
                            .where("check_in <= ?", today)
                            .order(created_at: :desc)

    @checked_in_bookings = Booking.includes(:user, room: :room_level)
                                  .where(status: "checked_in")
                                  .order(:check_out, created_at: :desc)

    rooms = Room.includes(:room_level).to_a.sort_by { |room| room.room_number.to_i }
    @floors = rooms.filter_map { |room| floor_from_room_number(room.room_number) }.uniq.sort
    @selected_floor = params[:floor].to_i if params[:floor].present?
    @rooms_for_panel = if @selected_floor.present? && @selected_floor.positive?
                         rooms.select { |room| floor_from_room_number(room.room_number) == @selected_floor }
                       else
                         rooms
                       end

    @booking = nil
    @can_validate_booking = false
    @booking_validation_message = nil
    @checkout_booking = nil
    @can_checkout_booking = false
    @checkout_message = nil
    if params[:code].present?
      @booking = Booking.includes(:user, room: :room_level)
                        .find_by(booking_code: params[:code].strip)
      if @booking.present?
        @can_validate_booking = @booking.paid? && @booking.check_in <= today
        @booking_validation_message =
          if @booking.complete?
            "Booking ini sudah selesai."
          elsif @booking.expired?
            "Booking ini sudah expired karena tidak divalidasi sampai lewat tanggal check-out."
          elsif @booking.checked_in?
            "Booking ini sudah divalidasi dan tamu sudah check-in."
          elsif !@booking.paid?
            "Booking ini tidak bisa divalidasi dengan status #{@booking.status.humanize}."
          elsif !@can_validate_booking
            "Booking hanya bisa divalidasi pada tanggal check-in (#{@booking.check_in})."
          end
      end
    end

    if params[:checkout_code].present?
      @checkout_booking = Booking.includes(:user, room: :room_level)
                                 .find_by(booking_code: params[:checkout_code].strip)
      if @checkout_booking.present?
        @can_checkout_booking = @checkout_booking.checked_in?
        @checkout_message =
          if @checkout_booking.complete?
            "Booking ini sudah checkout."
          elsif @checkout_booking.expired?
            "Booking ini sudah expired."
          elsif !@checkout_booking.checked_in?
            "Booking ini belum check-in, jadi belum bisa checkout."
          elsif @checkout_booking.overdue_checkout?
            "Booking ini sudah melewati tanggal checkout dan ditandai telat."
          end
      end
    end
  end

  def show
  end

  def new_reservation
    load_reservation_form
    @reservation_items = reservation_default_items
    @reservation_name = ""
    @reservation_email = ""
  end

  def create_reservation
    check_in = parse_reservation_date(params.dig(:reservation, :check_in))
    check_out = parse_reservation_date(params.dig(:reservation, :check_out))
    items = reservation_items
    guest_name = params.dig(:reservation, :guest_name).to_s.strip
    guest_email = params.dig(:reservation, :guest_email).to_s.strip.downcase

    if guest_name.blank? || guest_email.blank?
      return render_invalid_reservation(check_in:, check_out:, items:, guest_name:, guest_email:, message: "Nama dan email tamu wajib diisi")
    end

    if check_in.blank? || check_out.blank?
      return render_invalid_reservation(check_in:, check_out:, items:, guest_name:, guest_email:, message: "Tanggal check-in dan check-out wajib diisi")
    end

    if check_out <= check_in
      return render_invalid_reservation(check_in:, check_out:, items:, guest_name:, guest_email:, message: "Tanggal check-out harus setelah check-in")
    end

    if items.empty?
      return render_invalid_reservation(check_in:, check_out:, items:, guest_name:, guest_email:, message: "Pilih minimal 1 tipe kamar")
    end

    user = build_reservation_user!(guest_name:, guest_email:)
    booking_code = Booking.generate_shared_booking_code

    room_level_ids = items.map { |item| item[:room_level_id] }
    room_level_map = RoomLevel.where(id: room_level_ids).index_by { |room_level| room_level.id.to_s }

    Booking.transaction do
      booked_room_ids = []

      items.each do |item|
        room_level = room_level_map[item[:room_level_id]]
        quantity = item[:quantity]

        raise ReservationCreationError, "Tipe kamar tidak valid" unless room_level

        unavailable_room_ids = Booking.unavailable_room_ids(check_in:, check_out:)
        available_rooms = Room.where(room_level_id: room_level.id)
                              .where.not(id: unavailable_room_ids)
                              .lock
                              .limit(quantity)

        if available_rooms.size < quantity
          raise ReservationCreationError, "Kamar tersedia untuk #{room_level.name} hanya #{available_rooms.size}"
        end

        available_rooms.each do |room|
          user.bookings.create!(
            room: room,
            check_in: check_in,
            check_out: check_out,
            status: "paid",
            payment_status: "paid",
            booking_code: booking_code
          )

          booked_room_ids << room.id
        end
      end

      Booking.sync_room_statuses!(booked_room_ids.uniq)
    end

    redirect_to history_admin_bookings_path(code: booking_code), notice: "Reservasi berhasil dibuat untuk #{guest_name}"
  rescue ActiveRecord::RecordInvalid => e
    render_invalid_reservation(
      check_in:,
      check_out:,
      items: items,
      guest_name: guest_name,
      guest_email: guest_email,
      message: e.record.errors.full_messages.to_sentence.presence || "Reservasi gagal dibuat"
    )
  rescue ReservationCreationError, StandardError => e
    render_invalid_reservation(check_in:, check_out:, items:, guest_name:, guest_email:, message: e.message.presence || "Reservasi gagal dibuat")
  end

  def history
    @booking_histories = Booking.includes(:user, room: :room_level)
                                .order(created_at: :desc)

    if @filter_code.present?
      @booking_histories = @booking_histories.where("booking_code LIKE ?", "%#{@filter_code}%")
    end

    if @filter_status.present? && Booking.statuses.key?(@filter_status)
      @booking_histories = @booking_histories.where(status: @filter_status)
    end
  end

  def validate
    if @booking.checked_in? || @booking.complete?
      redirect_to admin_bookings_path, alert: "Booking sudah tervalidasi"
      return
    end

    if @booking.expired?
      redirect_to admin_bookings_path, alert: "Booking sudah expired dan tidak bisa divalidasi"
      return
    end

    if @booking.check_in != Date.current
      redirect_to admin_bookings_path, alert: "Booking hanya bisa divalidasi pada tanggal check-in (#{@booking.check_in})."
      return
    end

    Booking.transaction do
      @booking.update!(status: "checked_in")
      Booking.sync_room_statuses!([@booking.room_id])
    end

    redirect_to admin_bookings_path, notice: "Booking berhasil check-in"
  end

  def checkout
    unless @booking.checked_in?
      redirect_to admin_bookings_path, alert: "Booking belum check-in sehingga belum bisa checkout"
      return
    end

    Booking.transaction do
      @booking.update!(status: "complete")
      Booking.sync_room_statuses!([@booking.room_id])
    end

    redirect_to admin_bookings_path, notice: "Checkout berhasil"
  end

  def update
    Booking.transaction do
      @booking.update!(booking_params)

      if @booking.saved_change_to_status? || @booking.saved_change_to_check_in? || @booking.saved_change_to_check_out?
        Booking.sync_room_statuses!([@booking.room_id])
      end
    end

    redirect_back fallback_location: admin_dashboard_path, notice: "Booking berhasil diupdate"
  rescue ActiveRecord::RecordInvalid => e
    redirect_back fallback_location: admin_dashboard_path, alert: e.record.errors.full_messages.to_sentence
  end

  def destroy
    room_id = @booking.room_id

    Booking.transaction do
      @booking.destroy!
      Booking.sync_room_statuses!([room_id])
    end

    redirect_back fallback_location: admin_bookings_path, notice: "Booking berhasil dihapus"
  rescue ActiveRecord::RecordNotDestroyed => e
    redirect_back fallback_location: admin_bookings_path, alert: e.record.errors.full_messages.to_sentence.presence || "Booking gagal dihapus"
  end

  private

  def set_booking
    @booking = Booking.includes(:user, room: :room_level).find(params[:id])
  end

  def booking_params
    params.require(:booking).permit(:check_in, :check_out, :status)
  end

  def load_reservation_form(check_in: nil, check_out: nil, items: nil)
    @booking = Booking.new(check_in: check_in, check_out: check_out)
    @room_levels = RoomLevel.all
    @reservation_items = items.presence || reservation_default_items
  end

  def render_invalid_reservation(check_in:, check_out:, items:, guest_name:, guest_email:, message:)
    load_reservation_form(check_in:, check_out:, items:)
    @reservation_name = guest_name
    @reservation_email = guest_email
    flash.now[:alert] = message
    render :new_reservation, status: :unprocessable_entity
  end

  def reservation_items
    Array(params.dig(:reservation, :items)).filter_map do |item|
      room_level_id = item[:room_level_id].to_s
      quantity = item[:quantity].to_i
      next if room_level_id.blank? || quantity <= 0

      { room_level_id: room_level_id, quantity: quantity }
    end
  end

  def reservation_default_items
    [{ room_level_id: "", quantity: 1 }]
  end

  def parse_reservation_date(value)
    return if value.blank?

    Date.parse(value)
  rescue ArgumentError
    nil
  end

  def build_reservation_user!(guest_name:, guest_email:)
    user = User.find_or_initialize_by(email: guest_email)

    if user.new_record?
      username = guest_name.presence || "Guest"
      username = unique_reservation_username(username)
      random_password = SecureRandom.hex(8)

      user.username = username
      user.password = random_password
      user.password_confirmation = random_password
    elsif user.username.blank?
      user.username = unique_reservation_username(guest_name.presence || "Guest", except_user_id: user.id)
    end

    user.save! if user.changed?
    user
  end

  def unique_reservation_username(base_username, except_user_id: nil)
    clean_base = base_username.to_s.strip.presence || "Guest"
    username = clean_base
    counter = 1

    loop do
      relation = User.where(username: username)
      relation = relation.where.not(id: except_user_id) if except_user_id.present?
      return username unless relation.exists?

      counter += 1
      username = "#{clean_base} #{counter}"
    end
  end

  def ensure_resepsionis!
    redirect_to admin_bookings_path, alert: "Menu ini khusus resepsionis" unless current_user.resepsionis?
  end

  def load_booking_history_filters
    @filter_code = params[:code].to_s.strip
    @filter_status = params[:status].to_s.strip
    @history_status_options = Booking.statuses.keys
  end

  def floor_from_room_number(room_number)
    number = room_number.to_i
    return nil if number < 100

    number / 100
  end
end
