class Room < ApplicationRecord
  belongs_to :room_level
  has_many :bookings

  enum :status, { available: "available", paid: "paid", booked: "booked" }
end
