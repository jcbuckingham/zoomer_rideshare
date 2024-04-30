class AddNameToDrivers < ActiveRecord::Migration[7.1]
  def change
    add_column :drivers, :name, :string
  end
end
