class ShipmentLocationsConsumer < Karafka::BaseConsumer
  def consume
    messages.each do |message|
      process_location_update(JSON.parse(message.payload))
    rescue JSON::ParserError => e
      Rails.logger.error "Failed to parse location message: #{e.message}"
    rescue => e
      Rails.logger.error "Error processing location update: #{e.message}"
    end
  end

  private

  def process_location_update(data)
    shipment_identifier = data['shipment_identifier']
    latitude = data['latitude'].to_f
    longitude = data['longitude'].to_f
    recorded_at = Time.at(data['recorded_at'] / 1000.0) # Convert from milliseconds
    address = data['address']
    speed = data['speed']&.to_f

    # Find the shipment
    shipment = Shipment.find_by(shipment_identifier: shipment_identifier)
    unless shipment
      Rails.logger.warn "Shipment not found: #{shipment_identifier}"
      return
    end

    # Create location record
    location = shipment.shipment_locations.create!(
      latitude: latitude,
      longitude: longitude,
      recorded_at: recorded_at,
      address: address,
      speed: speed
    )

    Rails.logger.info "Created location for #{shipment_identifier}: #{latitude}, #{longitude}"

    # Process geofence rules and update status
    process_geofence_rules(shipment, latitude, longitude)
  end

  def process_geofence_rules(shipment, latitude, longitude)
    current_status = shipment.current_status
    new_status = determine_status_from_location(shipment, latitude, longitude)
    
    if new_status != current_status
      update_shipment_status(shipment, new_status, latitude, longitude)
    end
  end

  def determine_status_from_location(shipment, latitude, longitude)
    source_distance = calculate_distance(
      latitude, longitude,
      shipment.source_latitude, shipment.source_longitude
    )
    
    destination_distance = calculate_distance(
      latitude, longitude,
      shipment.destination_latitude, shipment.destination_longitude
    )

    # Geofence rules
    case shipment.current_status
    when 'prepared'
      # Transition to picked_up when leaving source zone
      return 'picked_up' if source_distance >= 1000 # 1km
    when 'picked_up'
      # Transition to in_transit when far from source
      return 'in_transit' if source_distance >= 3000 # 3km
    when 'in_transit'
      # Transition to out_for_delivery when near destination
      return 'out_for_delivery' if destination_distance <= 2000 # 2km
    when 'out_for_delivery'
      # Transition to delivered when at destination
      return 'delivered' if destination_distance <= 500 # 500m
    end

    # Special case: if at source and not prepared, set to prepared
    if source_distance <= 500 && shipment.current_status != 'prepared'
      return 'prepared'
    end

    shipment.current_status
  end

  def update_shipment_status(shipment, new_status, latitude, longitude)
    # Create status history record
    shipment.shipment_status_histories.create!(
      status: new_status,
      location: "#{latitude}, #{longitude}",
      notes: "Status changed via geofence processing",
      recorded_at: Time.current
    )

    # Update shipment status
    shipment.update!(current_status: new_status)

    Rails.logger.info "Updated #{shipment.shipment_identifier} status: #{shipment.current_status} -> #{new_status}"
  end

  def calculate_distance(lat1, lon1, lat2, lon2)
    # Haversine formula for calculating distance between two points
    rad_per_deg = Math::PI / 180
    rkm = 6371 # Earth's radius in kilometers
    rm = rkm * 1000 # Earth's radius in meters

    dlat_rad = (lat2 - lat1) * rad_per_deg
    dlon_rad = (lon2 - lon1) * rad_per_deg

    lat1_rad = lat1 * rad_per_deg
    lat2_rad = lat2 * rad_per_deg

    a = Math.sin(dlat_rad / 2)**2 + Math.cos(lat1_rad) * Math.cos(lat2_rad) * Math.sin(dlon_rad / 2)**2
    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))

    rm * c # Distance in meters
  end
end
