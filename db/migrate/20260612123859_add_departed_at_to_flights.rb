class AddDepartedAtToFlights < ActiveRecord::Migration[8.1]
  def change
    add_column :flights, :departed_at, :datetime
  end
end
