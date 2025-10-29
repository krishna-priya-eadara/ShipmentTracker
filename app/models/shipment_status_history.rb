class ShipmentStatusHistory < ApplicationRecord
  belongs_to :shipment, foreign_key: :shipment_id, primary_key: :shipment_identifier
  
  validates :shipment_id, presence:true
  validates :status, presence:true
  validates :latitude, presence:true
  validates :longitude, presence:true
  validates :address, presence:true
  # notes is optional
  validates :changed_at, presence:true
end
