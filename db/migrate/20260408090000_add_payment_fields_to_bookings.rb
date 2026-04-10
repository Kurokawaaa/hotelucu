class AddPaymentFieldsToBookings < ActiveRecord::Migration[8.1]
  def change
    add_column :bookings, :payment_status, :string, null: false, default: "pending"
    add_column :bookings, :midtrans_snap_token, :string
  end
end
