class AddCoordsToRides < ActiveRecord::Migration[7.1]
  def change
    add_column :rides, :start_coords, :string
    add_column :rides, :destination_coords, :string
  end
end
