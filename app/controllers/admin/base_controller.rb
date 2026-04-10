# app/controllers/admin/base_controller.rb
class Admin::BaseController < ApplicationController
  layout "admin"
  before_action :authenticate_user!
  before_action :authorize_admin_panel
  before_action :restrict_resepsionis_access

  private

  def authorize_admin_panel
    redirect_to root_path, alert: "Akses ditolak" unless current_user.admin_panel?
  end

  def restrict_resepsionis_access
    return unless current_user.resepsionis?
    return if controller_path == "admin/bookings"
    return if controller_path == "admin/dashboard"

    redirect_to admin_bookings_path, alert: "Akses resepsionis hanya untuk menu Booking"
  end
end
