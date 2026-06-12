class CreatePlanes < ActiveRecord::Migration[8.1]
  def change
    create_table :planes do |t|
      t.references :player, null: false, foreign_key: true
      t.string :name
      t.string :plane_type
      t.integer :speed
      t.integer :range
      t.integer :capacity
      t.references :current_airport, null: false, foreign_key: { to_table: :airports }

      t.timestamps
    end
  end
end
