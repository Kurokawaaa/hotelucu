class AddRoomLevelToFacilities < ActiveRecord::Migration[7.1]
  def change
    add_reference :facilities, :room_level, foreign_key: true
  end
end
