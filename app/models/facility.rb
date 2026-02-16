class Facility < ApplicationRecord
  has_many :room_level_facilities, dependent: :destroy
  has_many :room_levels, through: :room_level_facilities

  validates :name, presence: true
end
