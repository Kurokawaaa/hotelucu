class BookingsController < ApplicationController
  before_action :authenticate_user!

  def index
  @bookings = current_user.bookings.includes(room: :room_level)
end

  def new
    @booking = Booking.new
    @room_levels = RoomLevel.all
  end

  def create
    check_in = params.dig(:booking, :check_in)
    check_out = params.dig(:booking, :check_out)

    items = Array(params.dig(:booking, :items)).map do |item|
      {
        room_level_id: item[:room_level_id].to_s,
        quantity: item[:quantity].to_i
      }
    end

    items = items.select { |item| item[:room_level_id].present? && item[:quantity] > 0 }

    if items.empty?
      @booking = Booking.new(check_in: check_in, check_out: check_out)
      @room_levels = RoomLevel.all
      flash.now[:alert] = "Pilih minimal 1 tingkatan kamar"
      render :new, status: :unprocessable_entity
      return
    end

    room_level_ids = items.map { |i| i[:room_level_id] }
    room_level_map = RoomLevel.where(id: room_level_ids).index_by { |rl| rl.id.to_s }

    Booking.transaction do
      items.each do |item|
        room_level = room_level_map[item[:room_level_id]]
        available_rooms = Room.where(room_level_id: item[:room_level_id], status: "available")
                              .limit(item[:quantity])

        if available_rooms.size < item[:quantity]
          raise ActiveRecord::RecordInvalid.new(Booking.new),
                "Kamar tersedia untuk #{room_level&.name || 'tingkatan ini'} hanya #{available_rooms.size}"
        end

        available_rooms.each do |room|
          current_user.bookings.create!(
            room: room,
            check_in: check_in,
            check_out: check_out,
            status: "paid"
          )
          room.update!(status: "paid")
        end
      end
    end

    redirect_to bookings_path, notice: "Booking berhasil"
  rescue ActiveRecord::RecordInvalid => e
    @booking = Booking.new(check_in: check_in, check_out: check_out)
    @room_levels = RoomLevel.all
    flash.now[:alert] = e.message.presence || "Booking gagal"
    render :new, status: :unprocessable_entity
  end

  def show
    @booking = Booking.find(params[:id])
  end

  private

  def booking_params
    params.require(:booking).permit(:check_in, :check_out)
  end
end
