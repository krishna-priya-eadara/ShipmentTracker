class CreateShipmentStatusHistories < ActiveRecord::Migration[8.1]
  def change
    create_table :shipment_status_histories do |t|
      t.string :shipment_id, null: false
      t.string :status, null: false
      t.float :latitude, null: false
      t.float :longitude, null: false
      t.string :address, null: false
      t.text :notes
      t.datetime :changed_at, null: false

      t.timestamps
    end

    add_foreign_key :shipment_status_histories, :shipments,
                    column: :shipment_id,
                    primary_key: :shipment_identifier
  end
end
