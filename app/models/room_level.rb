# app/models/room_level.rb
class RoomLevel < ApplicationRecord
  has_many :room_level_facilities, dependent: :destroy
  has_many :facilities, through: :room_level_facilities

  accepts_nested_attributes_for :room_level_facilities, allow_destroy: true
end
