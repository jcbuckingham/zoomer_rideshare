class AddCoordsToDrivers < ActiveRecord::Migration[7.1]
  def change
    add_column :drivers, :coords, :string
  end
end
