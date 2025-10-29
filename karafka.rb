class KarafkaApp < Karafka::App
  setup do |config|
    config.client_id = 'my_app_client'
    config.kafka = { 'bootstrap.servers': 'localhost:9092' } # update with your Kafka broker
  end

  consumer_groups.draw do
    # Define your consumer groups here
    # example:
    # consumer_group :shipments do
    #   topic :shipment_created do
    #     consumer ShipmentCreatedConsumer
    #   end
    # end
  end
end