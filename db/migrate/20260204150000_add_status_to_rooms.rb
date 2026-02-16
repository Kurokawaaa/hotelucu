class AddStatusToRooms < ActiveRecord::Migration[8.1]
  def change
    add_column :rooms, :status, :string, default: "available", null: false
  end
end
