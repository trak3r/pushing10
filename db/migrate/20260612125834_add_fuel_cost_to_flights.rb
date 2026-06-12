class AddFuelCostToFlights < ActiveRecord::Migration[8.1]
  def change
    add_column :flights, :fuel_cost, :integer
  end
end
