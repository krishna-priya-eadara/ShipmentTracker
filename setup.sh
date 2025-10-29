#!/bin/bash

# Shipment Tracker Setup Script
# This script helps set up the shipment tracker application

set -e

echo "🚚 Shipment Tracker Setup Script"
echo "================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in the right directory
if [ ! -f "Gemfile" ]; then
    print_error "Please run this script from the shipment-tracker root directory"
    exit 1
fi

print_status "Starting setup process..."

# Step 1: Install Ruby dependencies
print_status "Installing Ruby dependencies..."
bundle install
print_success "Ruby dependencies installed"

# Step 2: Install JavaScript dependencies
print_status "Installing JavaScript dependencies..."
if command -v npm &> /dev/null; then
    npm install
    print_success "JavaScript dependencies installed"
else
    print_warning "npm not found, skipping JavaScript dependencies"
fi

# Step 3: Database setup
print_status "Setting up database..."
rails db:create
rails db:migrate
rails db:seed
print_success "Database setup complete"

# Step 4: Check for Kafka
print_status "Checking for Kafka installation..."
if command -v kafka-topics &> /dev/null; then
    print_success "Kafka is installed"
    
    # Check if Kafka is running
    if pgrep -f "kafka.Kafka" > /dev/null; then
        print_success "Kafka server is running"
    else
        print_warning "Kafka server is not running. Please start it manually:"
        echo "  zookeeper-server-start /opt/homebrew/etc/kafka/zookeeper.properties &"
        echo "  kafka-server-start /opt/homebrew/etc/kafka/server.properties &"
    fi
    
    # Create topic if it doesn't exist
    print_status "Creating Kafka topic..."
    kafka-topics --create --topic shipment_locations --bootstrap-server localhost:9092 --partitions 1 --replication-factor 1 2>/dev/null || print_warning "Topic might already exist"
    print_success "Kafka topic created"
else
    print_warning "Kafka not found. Please install Kafka manually:"
    echo "  brew install kafka  # macOS"
    echo "  sudo apt-get install kafka  # Ubuntu/Debian"
fi

# Step 5: Check for Google Maps API key
print_status "Checking Google Maps API configuration..."
if rails credentials:show | grep -q "google_maps_api_key"; then
    print_success "Google Maps API key is configured"
else
    print_warning "Google Maps API key not found. Please add it:"
    echo "  rails credentials:edit"
    echo "  # Add: google_maps_api_key: YOUR_API_KEY"
fi

# Step 6: Check for required services
print_status "Checking required services..."

# Check PostgreSQL
if command -v psql &> /dev/null; then
    print_success "PostgreSQL is installed"
else
    print_error "PostgreSQL not found. Please install PostgreSQL"
fi

# Check Ruby version
ruby_version=$(ruby -v | cut -d' ' -f2)
print_status "Ruby version: $ruby_version"

# Check Rails version
rails_version=$(rails -v | cut -d' ' -f2)
print_status "Rails version: $rails_version"

echo ""
print_success "Setup completed!"
echo ""
echo "Next steps:"
echo "1. Start Kafka (if not already running):"
echo "   zookeeper-server-start /opt/homebrew/etc/kafka/zookeeper.properties &"
echo "   kafka-server-start /opt/homebrew/etc/kafka/server.properties &"
echo ""
echo "2. Start the Rails server:"
echo "   rails server"
echo ""
echo "3. Start the Karafka consumer (in another terminal):"
echo "   bundle exec karafka server"
echo ""
echo "4. Access the application:"
echo "   - Main App: http://localhost:3000"
echo "   - GPS Simulator: http://localhost:3000/simulator"
echo ""
echo "For detailed instructions, see SETUP_GUIDE.md"
