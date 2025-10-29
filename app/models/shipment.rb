class Shipment < ApplicationRecord
    has_many :shipment_locations, foreign_key: :shipment_id, primary_key: :shipment_identifier, dependent: :destroy
    has_many :shipment_status_histories, foreign_key: :shipment_id, primary_key: :shipment_identifier, dependent: :destroy

    validates :shipment_identifier, presence: true, uniqueness: true
    validates :source_latitude, :source_longitude, :destination_latitude, :destination_longitude, presence: true

     enum :current_status, { prepared: 'prepared', picked_up: 'picked_up', in_transit: 'in_transit', out_for_delivery: 'out_for_delivery', delivered: 'delivered', exception: 'exception' }
end
