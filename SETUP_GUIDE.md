# Shipment Tracker - Setup Guide

A real-time shipment tracking application built with Ruby on Rails, Kafka, and Google Maps API.

## Prerequisites

Before setting up this application, ensure you have the following installed:

- **Ruby 3.4.7** (or compatible version)
- **Rails 8.1.0** (or compatible version)
- **PostgreSQL** (for database)
- **Kafka** (for event streaming)
- **Node.js** (for JavaScript dependencies)
- **Git** (for version control)

## Quick Setup

### 1. Clone the Repository

```bash
git clone <repository-url>
cd shipment-tracker
```

### 2. Install Dependencies

```bash
# Install Ruby gems
bundle install

# Install JavaScript dependencies
npm install
```

### 3. Database Setup

```bash
# Create and setup the database
rails db:create
rails db:migrate
rails db:seed
```

### 4. Install Kafka

#### macOS (using Homebrew)
```bash
brew install kafka
```

#### Ubuntu/Debian
```bash
sudo apt-get update
sudo apt-get install kafka
```

#### Manual Installation
1. Download Kafka from [https://kafka.apache.org/downloads](https://kafka.apache.org/downloads)
2. Extract the archive
3. Add Kafka to your PATH

### 5. Start Required Services

#### Start Kafka
```bash
# Start Zookeeper (in a separate terminal)
zookeeper-server-start /opt/homebrew/etc/kafka/zookeeper.properties

# Start Kafka Server (in another terminal)
kafka-server-start /opt/homebrew/etc/kafka/server.properties
```

#### Create Kafka Topic
```bash
kafka-topics --create --topic shipment_locations --bootstrap-server localhost:9092 --partitions 1 --replication-factor 1
```

### 6. Configure Google Maps API

1. Get a Google Maps API key from [Google Cloud Console](https://console.cloud.google.com/)
2. Enable the following APIs:
   - Maps JavaScript API
   - Geocoding API
   - Places API

3. Add the API key to Rails credentials:
```bash
rails credentials:edit
```

Add the following content:
```yaml
google_maps_api_key: YOUR_GOOGLE_MAPS_API_KEY_HERE
```

### 7. Start the Application

#### Terminal 1: Start Rails Server
```bash
rails server
```

#### Terminal 2: Start Karafka Consumer
```bash
bundle exec karafka server
```

### 8. Access the Application

- **Main Application**: http://localhost:3000
- **GPS Simulator**: http://localhost:3000/simulator

## Detailed Setup Instructions

### Database Configuration

The application uses PostgreSQL. Update `config/database.yml` if needed:

```yaml
development:
  adapter: postgresql
  encoding: unicode
  database: shipment_tracker_development
  username: your_username
  password: your_password
  host: localhost
  port: 5432
```

### Kafka Configuration

The Kafka configuration is in `config/karafka.rb`. Default settings:

- **Bootstrap Server**: localhost:9092
- **Client ID**: shipment_tracker_client
- **Topic**: shipment_locations

### Environment Variables

Create a `.env` file (optional):

```bash
# Database
DATABASE_URL=postgresql://username:password@localhost/shipment_tracker_development

# Kafka
KAFKA_BOOTSTRAP_SERVERS=localhost:9092

# Google Maps
GOOGLE_MAPS_API_KEY=your_api_key_here
```

## Features

### 🚚 Shipment Tracking
- Real-time location updates
- Interactive Google Maps integration
- Status history tracking
- Geofencing-based status updates

### 📡 Event-Driven Architecture
- Kafka-based message streaming
- Asynchronous location processing
- Scalable consumer architecture

### 🎮 GPS Simulator
- Web-based simulation interface
- Realistic GPS data generation
- Route simulation between cities
- Speed and timing controls

### 🗺️ Geofencing
- Automatic status transitions
- Distance-based rules
- Source and destination zones

## API Endpoints

### Shipments
- `GET /shipments` - List all shipments
- `GET /shipments/:id` - View shipment details
- `POST /shipments/:id/simulate_update` - Simulate single location update
- `POST /shipments/:id/start_simulation` - Start continuous simulation
- `POST /shipments/:id/stop_simulation` - Stop simulation

### Simulator
- `GET /simulator` - GPS simulator interface
- `POST /simulator/start_all` - Start simulation for all shipments
- `POST /simulator/stop_all` - Stop all simulations

## Testing the Application

### 1. Basic Functionality Test
```bash
# Test GPS simulation
rails runner "
shipment = Shipment.first
simulator = GpsSimulatorService.new(shipment)
simulator.simulate_single_update
puts 'Simulation completed!'
"
```

### 2. Kafka Integration Test
```bash
# Check if messages are being published
kafka-console-consumer --bootstrap-server localhost:9092 --topic shipment_locations --from-beginning --max-messages 5
```

### 3. Web Interface Test
1. Go to http://localhost:3000/simulator
2. Click "Simulate Update" on any shipment
3. Check the shipment details page for new location data

## Troubleshooting

### Common Issues

#### 1. "No topics to subscribe to" Error
```bash
# Ensure Kafka topic exists
kafka-topics --list --bootstrap-server localhost:9092

# Create topic if missing
kafka-topics --create --topic shipment_locations --bootstrap-server localhost:9092
```

#### 2. Google Maps Not Loading
- Verify API key is correctly set in credentials
- Check browser console for API errors
- Ensure required APIs are enabled in Google Cloud Console

#### 3. Database Connection Issues
```bash
# Check database status
rails db:version

# Reset database if needed
rails db:drop db:create db:migrate db:seed
```

#### 4. Karafka Consumer Not Processing
```bash
# Check if consumer is running
ps aux | grep karafka

# Restart consumer
pkill -f karafka
bundle exec karafka server
```

### Logs and Debugging

#### Rails Logs
```bash
tail -f log/development.log
```

#### Kafka Logs
```bash
# Check Kafka server logs
tail -f /opt/homebrew/var/log/kafka/server.log
```

#### Karafka Logs
```bash
# Enable debug logging
KARAFKA_ENV=development bundle exec karafka server
```

## Development

### Running Tests
```bash
# Run all tests
rails test

# Run specific test file
rails test test/models/shipment_test.rb
```

### Code Quality
```bash
# Run RuboCop
bundle exec rubocop

# Run Brakeman (security)
bundle exec brakeman
```

### Database Migrations
```bash
# Create new migration
rails generate migration AddNewFieldToShipments field_name:type

# Run migrations
rails db:migrate

# Rollback migration
rails db:rollback
```

## Production Deployment

### Environment Setup
1. Set production database credentials
2. Configure Kafka cluster endpoints
3. Set up Google Maps API key
4. Configure Redis for caching (if needed)

### Docker Deployment
```bash
# Build Docker image
docker build -t shipment-tracker .

# Run with Docker Compose
docker-compose up -d
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## License

This project is licensed under the MIT License.

## Support

For issues and questions:
1. Check the troubleshooting section
2. Review the logs
3. Create an issue in the repository
4. Contact the development team

---

**Happy Tracking! 🚚📦**
