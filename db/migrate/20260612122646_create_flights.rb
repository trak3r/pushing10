class CreateFlights < ActiveRecord::Migration[8.1]
  def change
    create_table :flights do |t|
      t.references :plane, null: false, foreign_key: true
      t.references :from_airport, null: false, foreign_key: { to_table: :airports }
      t.references :to_airport, null: false, foreign_key: { to_table: :airports }
      t.integer :distance
      t.integer :revenue
      t.datetime :completed_at

      t.timestamps
    end
  end
end
