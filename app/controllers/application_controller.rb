class ApplicationController < ActionController::Base
  # TAMBAHKAN BARIS INI:
  before_action :configure_permitted_parameters, if: :devise_controller?

  def after_sign_in_path_for(resource)
    if resource.admin?
      admin_root_path
    else
      home_path
    end
  end

  def after_sign_out_path_for(_resource_or_scope)
    new_user_session_path
  end

  protected # Sebaiknya diletakkan di bawah protected agar lebih rapi

  def configure_permitted_parameters
    # Untuk proses Sign Up
    devise_parameter_sanitizer.permit(:sign_up, keys: [:username])
    # Untuk proses Update Akun
    devise_parameter_sanitizer.permit(:account_update, keys: [:username])
  end
end