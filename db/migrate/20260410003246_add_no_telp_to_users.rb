class AddNoTelpToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :no_telp, :integer
  end
end
