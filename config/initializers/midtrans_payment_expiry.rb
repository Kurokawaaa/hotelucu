require Rails.root.join("app/services/midtrans_snap_service")

module MidtransPaymentExpiry
  def create_transaction!(booking_code:, gross_amount:, customer:, item_details:)
    body = {
      transaction_details: {
        order_id: booking_code,
        gross_amount: gross_amount.to_i
      },
      customer_details: {
        first_name: customer[:first_name].presence || "Guest",
        email: customer[:email]
      },
      item_details: item_details,
      expiry: {
        duration: Booking::PAYMENT_TIMEOUT_MINUTES,
        unit: "minute"
      }
    }

    send(:request_json, "/snap/v1/transactions", method: :post, body: body)
  end
end

MidtransSnapService.singleton_class.prepend(MidtransPaymentExpiry)
