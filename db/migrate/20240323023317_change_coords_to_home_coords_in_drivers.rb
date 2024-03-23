class ChangeCoordsToHomeCoordsInDrivers < ActiveRecord::Migration[7.1]
    def change
      rename_column :drivers, :coords, :home_coords
    end
end
