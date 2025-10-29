class CreateShipmentLocations < ActiveRecord::Migration[8.1]
  def change
    create_table :shipment_locations do |t|
      t.string :shipment_id, null: false
      t.float :latitude, null: false
      t.float :longitude, null: false
      t.bigint :recorded_at, null: false
      t.string :address
      t.float :speed

      t.timestamps
    end

    add_foreign_key :shipment_locations, :shipments,
                    column: :shipment_id,
                    primary_key: :shipment_identifier
  end
end
