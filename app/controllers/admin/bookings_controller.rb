class Admin::BookingsController < Admin::BaseController
  def index
    @paid_bookings = Booking.includes(:user, room: :room_level)
                            .where(status: "paid")
                            .order(created_at: :desc)

    rooms = Room.includes(:room_level).to_a.sort_by { |room| room.room_number.to_i }
    @floors = rooms.filter_map { |room| floor_from_room_number(room.room_number) }.uniq.sort
    @selected_floor = params[:floor].to_i if params[:floor].present?
    @rooms_for_panel = if @selected_floor.present? && @selected_floor.positive?
                         rooms.select { |room| floor_from_room_number(room.room_number) == @selected_floor }
                       else
                         rooms
                       end

    @booking = nil
    if params[:code].present?
      @booking = Booking.includes(:user, room: :room_level)
                        .find_by(booking_code: params[:code].strip)
    end
  end

  def show
    @booking = Booking.includes(:user, room: :room_level).find(params[:id])
  end

  def validate
    @booking = Booking.includes(:room).find(params[:id])

    if @booking.booked?
      redirect_to admin_bookings_path, alert: "Booking sudah tervalidasi"
      return
    end

    Booking.transaction do
      @booking.update!(status: "booked")
      @booking.room.update!(status: "booked")
    end

    redirect_to admin_bookings_path, notice: "Booking tervalidasi"
  end

  private

  def floor_from_room_number(room_number)
    number = room_number.to_i
    return nil if number < 100

    number / 100
  end
end
