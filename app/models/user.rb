# app/models/user.rb
class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :bookings

  def admin?
    role == "admin"
  end

  def resepsionis?
    role == "resepsionis"
  end

  def admin_panel?
    admin? || resepsionis?
  end
end
