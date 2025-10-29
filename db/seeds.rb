# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

require 'json'

puts "🌱 Starting database seeding..."

# Clear existing data
puts "🧹 Clearing existing data..."
ShipmentStatusHistory.destroy_all
ShipmentLocation.destroy_all
Shipment.destroy_all

# Load sample data from JSON files
sample_data_path = Rails.root.join('sample-data')

puts "📦 Loading shipment data..."
shipments_data = JSON.parse(File.read(sample_data_path.join('shipment.json')))

puts "🗺️ Loading shipment location data..."
locations_data = JSON.parse(File.read(sample_data_path.join('shipment_location.json')))

puts "📋 Loading shipment status history data..."
status_histories_data = JSON.parse(File.read(sample_data_path.join('shipment_status_history.json')))

# Create shipments
puts "Creating shipments..."
shipments_data.each do |shipment_data|
  shipment = Shipment.create!(
    shipment_identifier: shipment_data['shipment_identifier'],
    weight: shipment_data['weight'],
    height: shipment_data['height'],
    source_address: shipment_data['source_address'],
    destination_address: shipment_data['destination_address'],
    source_latitude: shipment_data['source_latitude'],
    source_longitude: shipment_data['source_longitude'],
    destination_latitude: shipment_data['destination_latitude'],
    destination_longitude: shipment_data['destination_longitude'],
    current_status: shipment_data['current_status']
  )
  puts "  ✅ Created shipment: #{shipment.shipment_identifier}"
end

# Create shipment locations
puts "Creating shipment locations..."
locations_data.each do |location_data|
  location = ShipmentLocation.create!(
    shipment_id: location_data['shipment_id'],
    latitude: location_data['latitude'],
    longitude: location_data['longitude'],
    recorded_at: location_data['recorded_at'],
    address: location_data['address'],
    speed: location_data['speed']
  )
  puts "  📍 Created location for shipment: #{location.shipment_id}"
end

# Create shipment status histories
puts "Creating shipment status histories..."
status_histories_data.each do |status_data|
  status_history = ShipmentStatusHistory.create!(
    shipment_id: status_data['shipment_id'],
    status: status_data['status'],
    latitude: status_data['latitude'],
    longitude: status_data['longitude'],
    address: status_data['address'],
    notes: status_data['notes'],
    changed_at: Time.parse(status_data['changed_at'])
  )
  puts "  📊 Created status history for shipment: #{status_history.shipment_id} - #{status_history.status}"
end

puts "🎉 Database seeding completed successfully!"
puts "📊 Summary:"
puts "  - Shipments: #{Shipment.count}"
puts "  - Locations: #{ShipmentLocation.count}"
puts "  - Status Histories: #{ShipmentStatusHistory.count}"
