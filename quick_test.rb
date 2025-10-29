#!/usr/bin/env ruby

require 'bundler/setup'
require_relative 'config/environment'

puts "🔍 Quick System Check - Shipment Tracker"
puts "=" * 50

# Check 1: Rails Server
puts "\n1. Rails Server Status"
begin
  response = `curl -s -o /dev/null -w "%{http_code}" http://localhost:3000`
  if response.strip == "200"
    puts "   ✅ Rails server is running on port 3000"
  else
    puts "   ❌ Rails server not responding (HTTP #{response.strip})"
  end
rescue
  puts "   ❌ Cannot check Rails server"
end

# Check 2: Database
puts "\n2. Database Status"
begin
  shipment_count = Shipment.count
  location_count = ShipmentLocation.count
  status_count = ShipmentStatusHistory.count
  
  puts "   ✅ Database connected"
  puts "   📊 Shipments: #{shipment_count}"
  puts "   📊 Locations: #{location_count}"
  puts "   📊 Status History: #{status_count}"
rescue => e
  puts "   ❌ Database error: #{e.message}"
end

# Check 3: Kafka
puts "\n3. Kafka Status"
begin
  kafka_status = `brew services list | grep kafka`.strip
  if kafka_status.include?("started")
    puts "   ✅ Kafka is running"
  else
    puts "   ❌ Kafka not running: #{kafka_status}"
  end
rescue
  puts "   ❌ Cannot check Kafka status"
end

# Check 4: Producer Test
puts "\n4. Kafka Producer Test"
begin
  test_shipment = Shipment.first
  if test_shipment
    ShipmentLocationProducer.publish_location(
      test_shipment.shipment_identifier,
      40.7589, -73.9851,
      Time.current.to_i * 1000,
      address: "Quick Test Location",
      speed: 30.0
    )
    puts "   ✅ Kafka producer working"
  else
    puts "   ⚠️  No shipments found to test with"
  end
rescue => e
  puts "   ❌ Kafka producer error: #{e.message}"
end

# Check 5: GPS Simulator
puts "\n5. GPS Simulator Test"
begin
  test_shipment = Shipment.first
  if test_shipment
    simulator = GpsSimulatorService.new(test_shipment)
    simulator.simulate_single_update
    puts "   ✅ GPS Simulator working"
  else
    puts "   ⚠️  No shipments found to test with"
  end
rescue => e
  puts "   ❌ GPS Simulator error: #{e.message}"
end

# Check 6: Consumer Processing
puts "\n6. Consumer Processing"
begin
  sleep(1) # Give consumer time to process
  test_shipment = Shipment.first
  if test_shipment
    test_shipment.reload
    location_count = test_shipment.shipment_locations.count
    if location_count > 0
      puts "   ✅ Consumer is processing messages (#{location_count} locations)"
    else
      puts "   ⚠️  No location records found - consumer may not be running"
    end
  end
rescue => e
  puts "   ❌ Consumer check error: #{e.message}"
end

puts "\n" + "=" * 50
puts "🎯 Ready to Test!"
puts "\nNext steps:"
puts "1. Open browser: http://localhost:3000"
puts "2. Click 'GPS Simulator' button"
puts "3. Click 'Simulate Update' on any shipment"
puts "4. Watch the magic happen! 🚀"

