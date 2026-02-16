class CreateRooms < ActiveRecord::Migration[8.1]
  def change
    create_table :rooms do |t|
      t.string :room_number
      t.references :room_level, null: false, foreign_key: true

      t.timestamps
    end
  end
end
