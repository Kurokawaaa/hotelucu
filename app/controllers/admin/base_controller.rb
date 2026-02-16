# app/controllers/admin/base_controller.rb
class Admin::BaseController < ApplicationController
    layout "admin"
  before_action :authenticate_user!
  before_action :authorize_admin

  private

  def authorize_admin
    redirect_to root_path, alert: "Akses ditolak" unless current_user.admin?
  end
end
