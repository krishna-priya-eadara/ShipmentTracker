class GpsSimulatorService
  def initialize(shipment)
    @shipment = shipment
    @current_lat = shipment.source_latitude
    @current_lng = shipment.source_longitude
    @start_time = Time.current
    @route_points = generate_route_points
    @current_route_index = 0
  end

  def simulate_route(duration_minutes = 60, update_interval_seconds = 30)
    end_time = @start_time + duration_minutes.minutes
    update_count = 0

    Rails.logger.info "Starting GPS simulation for #{@shipment.shipment_identifier} for #{duration_minutes} minutes"

    while Time.current < end_time && @current_route_index < @route_points.length - 1
      # Calculate current position along the route
      progress = calculate_route_progress
      current_position = interpolate_position(progress)
      
      # Add some realistic GPS noise (±10 meters)
      noisy_position = add_gps_noise(current_position)
      
      # Calculate speed based on route progress
      speed = calculate_speed(progress)
      
      # Publish location update
      publish_location_update(noisy_position, speed)
      
      update_count += 1
      Rails.logger.info "Published location update #{update_count} for #{@shipment.shipment_identifier}"
      
      # Wait for next update
      sleep(update_interval_seconds)
    end

    Rails.logger.info "GPS simulation completed for #{@shipment.shipment_identifier}. Published #{update_count} updates."
  end

  def simulate_single_update
    progress = calculate_route_progress
    current_position = interpolate_position(progress)
    noisy_position = add_gps_noise(current_position)
    speed = calculate_speed(progress)
    
    publish_location_update(noisy_position, speed)
    
    # Move to next route point if we've reached the current one
    if progress >= 1.0 && @current_route_index < @route_points.length - 1
      @current_route_index += 1
    end
  end

  private

  def generate_route_points
    # Generate intermediate points between source and destination
    # This creates a more realistic route with some curves
    points = []
    
    # Start point
    points << { lat: @shipment.source_latitude, lng: @shipment.source_longitude }
    
    # Generate 3-5 intermediate waypoints
    num_waypoints = rand(3..5)
    (1...num_waypoints).each do |i|
      progress = i.to_f / num_waypoints
      
      # Add some randomness to make the route more realistic
      lat_offset = (rand - 0.5) * 0.01 # ±0.005 degrees
      lng_offset = (rand - 0.5) * 0.01
      
      lat = interpolate_value(@shipment.source_latitude, @shipment.destination_latitude, progress) + lat_offset
      lng = interpolate_value(@shipment.source_longitude, @shipment.destination_longitude, progress) + lng_offset
      
      points << { lat: lat, lng: lng }
    end
    
    # End point
    points << { lat: @shipment.destination_latitude, lng: @shipment.destination_longitude }
    
    points
  end

  def calculate_route_progress
    elapsed_time = Time.current - @start_time
    total_duration = 60.minutes # Default 1 hour journey
    [elapsed_time / total_duration, 1.0].min
  end

  def interpolate_position(progress)
    if @current_route_index >= @route_points.length - 1
      return @route_points.last
    end

    current_point = @route_points[@current_route_index]
    next_point = @route_points[@current_route_index + 1]
    
    segment_progress = (progress * @route_points.length) - @current_route_index
    segment_progress = [segment_progress, 1.0].min

    {
      lat: interpolate_value(current_point[:lat], next_point[:lat], segment_progress),
      lng: interpolate_value(current_point[:lng], next_point[:lng], segment_progress)
    }
  end

  def interpolate_value(start_val, end_val, progress)
    start_val + (end_val - start_val) * progress
  end

  def add_gps_noise(position)
    # Add realistic GPS noise (±10 meters)
    noise_lat = (rand - 0.5) * 0.0001 # ~10 meters
    noise_lng = (rand - 0.5) * 0.0001
    
    {
      lat: position[:lat] + noise_lat,
      lng: position[:lng] + noise_lng
    }
  end

  def calculate_speed(progress)
    # Simulate realistic speed variations
    base_speed = 45.0 # km/h
    
    # Slower near start and end (city driving)
    if progress < 0.1 || progress > 0.9
      base_speed *= 0.6
    # Faster in the middle (highway driving)
    elsif progress > 0.2 && progress < 0.8
      base_speed *= 1.3
    end
    
    # Add some random variation
    base_speed + (rand - 0.5) * 10
  end

  def publish_location_update(position, speed)
    ShipmentLocationProducer.publish_location(
      @shipment.shipment_identifier,
      position[:lat],
      position[:lng],
      Time.current.to_i * 1000, # Convert to milliseconds
      address: reverse_geocode(position[:lat], position[:lng]),
      speed: speed
    )
  end

  def reverse_geocode(lat, lng)
    # Simple reverse geocoding - in production, use a real service
    "Location at #{lat.round(4)}, #{lng.round(4)}"
  end
end
