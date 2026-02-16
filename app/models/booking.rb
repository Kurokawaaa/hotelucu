class Booking < ApplicationRecord
  belongs_to :user
  belongs_to :room

  before_create :generate_booking_code
  enum :status, { paid: "paid", booked: "booked" }

  def generate_booking_code
    self.booking_code = "BK-#{Time.now.to_i}-#{SecureRandom.hex(2).upcase}"
  end
end
