class RenameBookedStatusesToCheckedInAndOccupied < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      UPDATE bookings
      SET status = 'checked_in'
      WHERE status = 'booked'
    SQL

    execute <<~SQL
      UPDATE rooms
      SET status = 'occupied'
      WHERE status = 'booked'
    SQL
  end

  def down
    execute <<~SQL
      UPDATE bookings
      SET status = 'booked'
      WHERE status = 'checked_in'
    SQL

    execute <<~SQL
      UPDATE rooms
      SET status = 'booked'
      WHERE status = 'occupied'
    SQL
  end
end
