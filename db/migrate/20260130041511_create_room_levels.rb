class CreateRoomLevels < ActiveRecord::Migration[8.1]
  def change
    create_table :room_levels do |t|
      t.string :name
      t.integer :price

      t.timestamps
    end
  end
end
