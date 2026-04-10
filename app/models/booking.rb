class Booking < ApplicationRecord
  PAYMENT_TIMEOUT_MINUTES = 10

  belongs_to :user
  belongs_to :room

  before_create :generate_booking_code

  enum :status, { pending: "pending", paid: "paid", checked_in: "checked_in", complete: "complete", expired: "expired" }
  enum :payment_status, { pending: "pending", paid: "paid", failed: "failed", expired: "expired" }, prefix: :payment

  scope :past_checkout, ->(today = Date.current) { where("check_out <= ?", today) }
  scope :with_blocking_statuses, -> { where(status: statuses.slice("pending", "paid", "checked_in").values) }
  scope :overlapping, ->(check_in, check_out) { where("check_in < ? AND check_out > ?", check_out, check_in) }
  scope :active_on, ->(date) { where("check_in <= ? AND check_out > ?", date, date) }
  scope :payment_pending, -> { where(status: "pending", payment_status: "pending") }
  scope :payment_timeout_reached, ->(time = Time.current) { payment_pending.where("created_at <= ?", time - PAYMENT_TIMEOUT_MINUTES.minutes) }

  def self.release_expired_rooms!
    sync_room_statuses!
  end

  def self.generate_shared_booking_code
    "BK-#{Time.current.to_i}-#{SecureRandom.hex(2).upcase}"
  end

  def self.status_for_stay(check_in:, check_out:, today: Date.current)
    "pending"
  end

  def self.sync_booking_statuses!(today: Date.current)
    transaction do
      payment_timeout_reached.update_all(status: "expired", payment_status: "expired")
      where(status: "paid").past_checkout(today).update_all(status: "expired")
      where(status: "pending").past_checkout(today).update_all(status: "expired", payment_status: "expired")
    end
  end

  def self.expire_payment_timeout!(scope)
    relation = scope.is_a?(ActiveRecord::Relation) ? scope : where(id: Array(scope).map { |record| record.respond_to?(:id) ? record.id : record })
    relation.payment_pending.update_all(status: "expired", payment_status: "expired")
  end

  def self.unavailable_room_ids(check_in:, check_out:)
    with_blocking_statuses
      .overlapping(check_in, check_out)
      .select(:room_id)
  end

  def self.sync_room_statuses!(room_ids = nil, today: Date.current)
    sync_booking_statuses!(today: today)

    rooms = room_ids.present? ? Room.where(id: room_ids) : Room.all

    rooms.find_each do |room|
      bookings = room.bookings.with_blocking_statuses

      active_booking = bookings
                       .active_on(today)
                       .order(Arel.sql("CASE status WHEN 'checked_in' THEN 0 WHEN 'paid' THEN 1 WHEN 'pending' THEN 2 ELSE 3 END"))
                       .first

      next_status = room_status_for(active_booking&.status)

      room.update_column(:status, Room.statuses.fetch(next_status))
    end
  end

  def self.room_status_for(booking_status)
    case booking_status
    when "checked_in"
      "occupied"
    when "paid", "pending"
      "paid"
    else
      "available"
    end
  end

  def generate_booking_code
    return if booking_code.present?

    self.booking_code = self.class.generate_shared_booking_code
  end

  def payment_deadline_at
    created_at + PAYMENT_TIMEOUT_MINUTES.minutes
  end

  def payment_timeout_reached?(time = Time.current)
    payment_pending? && created_at.present? && created_at <= time - PAYMENT_TIMEOUT_MINUTES.minutes
  end

  def overdue_checkout?(today = Date.current)
    checked_in? && check_out.present? && check_out < today
  end
end
