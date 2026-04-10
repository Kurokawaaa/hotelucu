class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :sync_room_statuses

  def after_sign_in_path_for(resource)
    if resource.admin_panel?
      resource.resepsionis? ? admin_bookings_path : admin_root_path
    else
      home_path
    end
  end

  def after_sign_out_path_for(_resource_or_scope)
    new_user_session_path
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:username, :no_telp])
    devise_parameter_sanitizer.permit(:account_update, keys: [:username, :no_telp])
  end

  def sync_room_statuses
    Booking.sync_room_statuses!
  end
end
