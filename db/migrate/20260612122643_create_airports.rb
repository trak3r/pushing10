class CreateAirports < ActiveRecord::Migration[8.1]
  def change
    create_table :airports do |t|
      t.string :name
      t.string :code
      t.float :latitude
      t.float :longitude

      t.timestamps
    end
  end
end
