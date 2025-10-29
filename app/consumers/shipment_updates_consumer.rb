class ShipmentUpdatesConsumer < ApplicationConsumer
  def consume
    params_batch.each do |message|
      puts "Received message: #{message.payload}"
      # process your shipment update here
    end
  end
end