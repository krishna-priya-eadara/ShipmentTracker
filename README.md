# 🚚 Shipment Tracker

A real-time shipment tracking application built with Ruby on Rails, Kafka, and Google Maps API. Features event-driven location updates, geofencing, and a GPS simulator for testing.

## 🚀 Quick Start

```bash
# 1. Clone and setup
git clone <repository-url>
cd shipment-tracker
bundle install
rails db:create db:migrate db:seed

# 2. Install Kafka (macOS)
brew install kafka
zookeeper-server-start /opt/homebrew/etc/kafka/zookeeper.properties &
kafka-server-start /opt/homebrew/etc/kafka/server.properties &

# 3. Create Kafka topic
kafka-topics --create --topic shipment_locations --bootstrap-server localhost:9092

# 4. Configure Google Maps API
rails credentials:edit
# Add: google_maps_api_key: YOUR_API_KEY

# 5. Start the application
rails server &
bundle exec karafka server &
```

**Access the app:**
- Main App: http://localhost:3000
- GPS Simulator: http://localhost:3000/simulator

📖 **For detailed setup instructions, see [SETUP_GUIDE.md](SETUP_GUIDE.md)**

# Installing dependencies

1. **Tailwindcss**
    * Add `gem "tailwindcss-rails" ` to gemfile
    * run bundle/install
    * run `rails tailwindcss:install`

# Creating db
    run `rails db:create`

# Running local server
    run `bin/rails server`

# DB Schemas creation
Shipment Model
| Field | Type | Notes |
|-------|------|-------|
| `shipment_identifier` | string | Unique, required |
| `weight` | float | In kilograms |
| `height` | float | In centimeters |
| `source_address` | string | Full address |
| `destination_address` | string | Full address |
| `source_latitude` | float | Source pickup coordinates |
| `source_longitude` | float | Source pickup coordinates |
| `destination_latitude` | float | Destination delivery coordinates |
| `destination_longitude` | float | Destination delivery coordinates |
| `current_status` | string / enum | Current status: `prepared`, `picked_up`, `in_transit`, `out_for_delivery`, `delivered`, `exception` |
| `created_at` | datetime | Shipment creation timestamp |
| `updated_at` | datetime | Last modification timestamp |

    rails g model Shipment shipment_identifier:string:uniq weight:float! height:float! source_address:string! destination_address:string! source_latitude:float! source_longitude:float! destination_latitude:float! destination_longitude:float! current_status:string!

| Field | Type | Notes |
|-------|------|-------|
| `latitude` | float | GPS latitude coordinate |
| `longitude` | float | GPS longitude coordinate |
| `recorded_at` | datetime or epoch in milliseconds | Chronological order |
| `shipment_id` | foreign key | belongs_to Shipment |
| `address` | string | Optional: reverse-geocoded address |
| `speed` | float | Optional: speed at this location (km/h) |

    rails g model ShipmentLocation shipment:references latitude:float! longitude:float! recorded_at:bigint! address:string speed:float

| Field | Type | Notes |
|-------|------|-------|
| `shipment_id` | foreign key | belongs_to Shipment |
| `status` | string / enum | Status at time of change: `prepared`, `picked_up`, `in_transit`, `out_for_delivery`, `delivered`, `exception` |
| `latitude` | float | Location where status changed |
| `longitude` | float | Location where status changed |
| `address` | string | Human-readable address of status change |
| `notes` | text | Optional: additional details about status change |
| `changed_at` | datetime | When the status changed |
| `created_at` | datetime | Record creation timestamp |

    rails g model ShipmentStatusHistory shipment:references! status:string! latitude:float! longitude:float! address:string! notes:text changed_at:datetime!

> Manually update migration scripts and models to make any changes to column names eg: reference column names


# Migrate db
    run `rails db:migrate`


# Kafka installation
    gem 'karafka'
    gem 'waterdrop'


# Running Application
    