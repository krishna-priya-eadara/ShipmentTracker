class ShipmentLocationProducer
  def self.publish_location(shipment_identifier, latitude, longitude, recorded_at, address: nil, speed: nil)
    message = {
      shipment_identifier: shipment_identifier,
      latitude: latitude,
      longitude: longitude,
      recorded_at: recorded_at,
      address: address,
      speed: speed
    }.compact

    # Use Karafka's producer directly
    Karafka.producer.produce_async(
      topic: 'shipment_locations',
      payload: message.to_json
    )
  end

  def self.publish_batch_locations(locations)
    locations.each do |location|
      publish_location(
        location[:shipment_identifier],
        location[:latitude],
        location[:longitude],
        location[:recorded_at],
        address: location[:address],
        speed: location[:speed]
      )
    end
  end
end
