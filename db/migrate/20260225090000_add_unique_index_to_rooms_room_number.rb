class AddUniqueIndexToRoomsRoomNumber < ActiveRecord::Migration[8.1]
  def change
    add_index :rooms, :room_number, unique: true
  end
end
