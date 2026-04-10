class Admin::DashboardController < Admin::BaseController
  layout "admin"

  def index
    @rooms = Room.count
    @users = User.count
    @total_admin = User.where(role: "admin").count
    @bookings = Booking.count
    @booking_histories = Booking.includes(:user).order(created_at: :desc)
    @name = current_user.username
    @role = current_user.role
  end
end
