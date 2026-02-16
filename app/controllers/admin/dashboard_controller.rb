class Admin::DashboardController < Admin::BaseController
  layout "admin"
  def index
    @rooms = Room.count
    @users = User.count
    @total_admin    = User.where(role: 'admin').count # Contoh jika ada filter admin
    @bookings = Booking.count
    @name = current_user.username
    @role = current_user.role
  end
end
