import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["searchInput", "shipmentCard", "map"]
  static values = { 
    apiKey: String,
    shipments: Array
  }

  connect() {
    // Hardcode API key (in production, consider using environment variables)
    this.apiKeyValue = 'AIzaSyAOVYRIgupAurZup5y1PRh8Ismb1A3lLao'
    
    // Get shipments from data attributes
    if (this.mapTarget) {
      const shipmentsData = this.mapTarget.getAttribute('data-shipment-index-shipments-value')
      
      if (shipmentsData) {
        try {
          this.shipmentsValue = JSON.parse(shipmentsData)
        } catch (e) {
          console.error("Error parsing shipments JSON:", e)
        }
      }
    }
    
    this.setupSearch()
    this.loadGoogleMapsAPI()
  }

  setupSearch() {
    if (this.hasSearchInputTarget) {
      this.searchInputTarget.addEventListener('input', this.handleSearch.bind(this))
    }
  }

  handleSearch(event) {
    const searchTerm = event.target.value.toLowerCase()
    
    this.shipmentCardTargets.forEach(card => {
      const shipmentId = card.querySelector('h3').textContent.toLowerCase()
      const status = card.querySelector('.inline-flex').textContent.toLowerCase()
      const sourceAddress = card.querySelector('.truncate').textContent.toLowerCase()
      
      const matches = shipmentId.includes(searchTerm) || 
                     status.includes(searchTerm) || 
                     sourceAddress.includes(searchTerm)
      
      card.style.display = matches ? 'block' : 'none'
    })
  }

  centerMapOnShipment(event) {
    const shipmentId = event.currentTarget.dataset.shipmentId || 
                      event.currentTarget.querySelector('h3').textContent
    
    // Dispatch event to map controller
    this.dispatch('centerOnShipment', { 
      target: this.element.querySelector('#map'),
      detail: { shipmentId }
    })
    
    this.highlightShipmentCard(shipmentId)
  }

  highlightShipmentCard(shipmentId) {
    // Remove previous highlights
    this.shipmentCardTargets.forEach(card => {
      card.classList.remove('bg-blue-50', 'border-blue-200')
    })
    
    // Find and highlight the matching card
    this.shipmentCardTargets.forEach(card => {
      const cardShipmentId = card.querySelector('h3').textContent
      if (cardShipmentId === shipmentId) {
        card.classList.add('bg-blue-50', 'border-blue-200')
        card.scrollIntoView({ behavior: 'smooth', block: 'center' })
      }
    })
  }

  // Map functionality
  loadGoogleMapsAPI() {
    console.log("Loading Google Maps API...")
    
    if (window.google && window.google.maps) {
      console.log("Google Maps API already loaded")
      this.initializeMap()
      return
    }

    if (!this.apiKeyValue) {
      console.error("No API key provided")
      console.log("Trying fallback API key...")
      // Fallback to hardcoded key for testing
      this.apiKeyValue = 'AIzaSyAOVYRIgupAurZup5y1PRh8Ismb1A3lLao'
    }

    const script = document.createElement('script')
    script.src = `https://maps.googleapis.com/maps/api/js?key=${this.apiKeyValue}&callback=initIndexMapCallback&libraries=geometry`
    script.async = true
    script.defer = true
    script.onerror = () => {
      console.error("Failed to load Google Maps API script")
      this.handleMapError('Failed to load Google Maps API')
    }
    
    // Set up global callback
    window.initIndexMapCallback = () => {
      console.log("Google Maps API loaded successfully")
      this.initializeMap()
    }
    window.gm_authFailure = () => {
      console.error("Google Maps API authentication failed")
      this.handleMapError('Invalid API key or authentication failed')
    }
    
    console.log("Adding Google Maps script to head")
    document.head.appendChild(script)
  }

  initializeMap() {
    try {
      if (!window.google || !window.google.maps) {
        console.error('Google Maps API not loaded properly')
        this.handleMapError('Google Maps API not loaded properly')
        return
      }

      this.map = new google.maps.Map(this.mapTarget, {
        zoom: 6,
        mapTypeId: 'roadmap',
        styles: [
          {
            featureType: 'poi',
            elementType: 'labels',
            stylers: [{ visibility: 'off' }]
          }
        ]
      })

      this.setupShipmentsMap()
    } catch (error) {
      console.error('Error initializing map:', error)
      this.handleMapError('Error initializing map')
    }
  }

  setupShipmentsMap() {
    const bounds = new google.maps.LatLngBounds()
    const markers = []

    // Create markers for each shipment
    this.shipmentsValue.forEach((shipment, index) => {
      const position = { 
        lat: parseFloat(shipment.source_latitude), 
        lng: parseFloat(shipment.source_longitude) 
      }
      
      bounds.extend(position)
      
      const marker = new google.maps.Marker({
        position: position,
        map: this.map,
        title: shipment.shipment_identifier,
        icon: {
          path: google.maps.SymbolPath.CIRCLE,
          scale: 8,
          fillColor: this.getStatusColor(shipment.current_status),
          fillOpacity: 1,
          strokeColor: '#ffffff',
          strokeWeight: 2
        }
      })
      
      const infoWindow = new google.maps.InfoWindow({
        content: `
          <div class="p-2">
            <h3 class="font-semibold text-sm">${shipment.shipment_identifier}</h3>
            <p class="text-xs text-gray-600">${shipment.current_status}</p>
            <p class="text-xs text-gray-500 mt-1">${shipment.source_address.split(',')[0]}</p>
          </div>
        `
      })
      
      marker.addListener('click', () => {
        infoWindow.open(this.map, marker)
        this.highlightShipmentCard(shipment.shipment_identifier)
      })
      
      markers.push(marker)
    })
    
    // Add destination markers
    this.shipmentsValue.forEach((shipment) => {
      const destPosition = { 
        lat: parseFloat(shipment.destination_latitude), 
        lng: parseFloat(shipment.destination_longitude) 
      }
      
      new google.maps.Marker({
        position: destPosition,
        map: this.map,
        title: 'Destination: ' + shipment.shipment_identifier,
        icon: {
          path: google.maps.SymbolPath.CIRCLE,
          scale: 6,
          fillColor: '#ef4444',
          fillOpacity: 1,
          strokeColor: '#ffffff',
          strokeWeight: 2
        }
      })
    })
    
    // Fit map to show all markers
    if (markers.length > 0) {
      console.log("Fitting map bounds for", markers.length, "markers")
      this.map.fitBounds(bounds)
    } else {
      console.log("No markers to fit bounds")
    }
    console.log("Shipments map setup complete")
  }

  centerMapOnShipment(event) {
    const shipmentId = event.currentTarget.dataset.shipmentId || 
                      event.currentTarget.querySelector('h3').textContent
    
    this.centerOnShipment(shipmentId)
    this.highlightShipmentCard(shipmentId)
  }

  centerOnShipment(shipmentId) {
    if (!this.shipmentsValue || !this.map) return

    const shipment = this.shipmentsValue.find(s => s.shipment_identifier === shipmentId)
    if (shipment) {
      const position = { 
        lat: parseFloat(shipment.source_latitude), 
        lng: parseFloat(shipment.source_longitude) 
      }
      
      this.map.setCenter(position)
      this.map.setZoom(10)
    }
  }

  getStatusColor(status) {
    switch(status) {
      case 'delivered': return '#10b981'
      case 'in_transit': return '#3b82f6'
      case 'out_for_delivery': return '#f59e0b'
      case 'prepared': return '#6b7280'
      case 'picked_up': return '#8b5cf6'
      case 'exception': return '#ef4444'
      default: return '#6b7280'
    }
  }

  handleMapError(message) {
    this.mapTarget.innerHTML = `
      <div class="p-4 text-center text-red-600 bg-red-50 rounded-lg">
        <h3 class="font-semibold text-lg mb-2">🗺️ Google Maps API Error</h3>
        <p class="mb-3">${message}</p>
        <div class="text-sm text-gray-600 bg-white p-3 rounded border">
          <p class="font-medium mb-2">To fix this issue:</p>
          <ol class="text-left space-y-1">
            <li>1. Go to <a href="https://console.cloud.google.com/" target="_blank" class="text-blue-600 hover:underline">Google Cloud Console</a></li>
            <li>2. Create a new project or select existing one</li>
            <li>3. Enable "Maps JavaScript API" and "Geocoding API"</li>
            <li>4. Create credentials (API Key)</li>
            <li>5. Replace the API key in the code</li>
          </ol>
        </div>
      </div>
    `
  }
}
