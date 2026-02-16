class AddStatusToBookings < ActiveRecord::Migration[8.1]
  def change
    add_column :bookings, :status, :string, default: "paid", null: false
  end
end
