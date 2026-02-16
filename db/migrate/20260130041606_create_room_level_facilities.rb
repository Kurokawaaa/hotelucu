class CreateRoomLevelFacilities < ActiveRecord::Migration[8.1]
  def change
    create_table :room_level_facilities do |t|
      t.references :room_level, null: false, foreign_key: true
      t.references :facility, null: false, foreign_key: true

      t.timestamps
    end
  end
end
