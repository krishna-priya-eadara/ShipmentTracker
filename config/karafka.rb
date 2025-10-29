# Load the consumer class
require_relative '../app/consumers/shipment_locations_consumer'

class KarafkaApp < Karafka::App
  setup do |config|
    config.client_id = 'shipment_tracker_client'
    config.kafka = { 'bootstrap.servers': 'localhost:9092' }
  end

  consumer_groups.draw do
    consumer_group :shipment_tracking do
      topic :shipment_locations do
        consumer ShipmentLocationsConsumer
      end
    end
  end
end