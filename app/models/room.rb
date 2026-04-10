class Room < ApplicationRecord
  belongs_to :room_level
  has_many :bookings

  before_validation :normalize_room_number

  validates :room_number, presence: true, uniqueness: true

  enum :status, { available: "available", paid: "paid", occupied: "occupied" }

  private

  def normalize_room_number
    self.room_number = room_number.to_s.strip
  end
end
