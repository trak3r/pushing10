class CreatePassengers < ActiveRecord::Migration[8.1]
  def change
    create_table :passengers do |t|
      t.string :name
      t.references :origin_airport, null: false, foreign_key: { to_table: :airports }
      t.references :destination_airport, null: false, foreign_key: { to_table: :airports }
      t.integer :reward
      t.references :player, foreign_key: true
      t.references :plane, foreign_key: true
      t.boolean :delivered, default: false

      t.timestamps
    end
  end
end
