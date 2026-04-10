class MidtransController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :notification

  def notification
    payload = JSON.parse(request.body.read)

    unless MidtransSnapService.verify_notification_signature?(payload)
      head :unauthorized
      return
    end

    booking_code = payload["order_id"]
    transaction_status = payload["transaction_status"]
    fraud_status = payload["fraud_status"]

    bookings = Booking.where(booking_code: booking_code)

    if bookings.blank?
      head :not_found
      return
    end

    apply_payment_status!(bookings, transaction_status:, fraud_status:)

    Booking.sync_room_statuses!(bookings.pluck(:room_id))

    head :ok
  rescue JSON::ParserError
    head :bad_request
  rescue StandardError
    head :internal_server_error
  end

  private

  def apply_payment_status!(bookings, transaction_status:, fraud_status:)
    if bookings.payment_pending.where("created_at <= ?", Time.current - Booking::PAYMENT_TIMEOUT_MINUTES.minutes).exists?
      Booking.expire_payment_timeout!(bookings)
      return
    end

    case transaction_status
    when "capture"
      if fraud_status == "challenge"
        bookings.update_all(payment_status: "pending", status: "pending")
      else
        bookings.update_all(payment_status: "paid", status: "paid")
      end
    when "settlement"
      bookings.update_all(payment_status: "paid", status: "paid")
    when "pending"
      bookings.update_all(payment_status: "pending", status: "pending")
    when "deny", "cancel", "expire", "failure"
      bookings.update_all(payment_status: "failed", status: "expired")
    else
      bookings.update_all(payment_status: "pending")
    end
  end
end
