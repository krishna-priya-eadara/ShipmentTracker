import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["map"]
  static values = { 
    apiKey: String,
    statusHistories: Array,
    locations: Array
  }

  connect() {
    // Hardcode API key (in production, consider using environment variables)
    this.apiKeyValue = 'AIzaSyAOVYRIgupAurZup5y1PRh8Ismb1A3lLao'
    
    // Get data from data attributes
    if (this.mapTarget) {
      const statusHistoriesData = this.mapTarget.getAttribute('data-shipment-details-status-histories-value')
      const locationsData = this.mapTarget.getAttribute('data-shipment-details-locations-value')
      
      if (statusHistoriesData) {
        try {
          this.statusHistoriesValue = JSON.parse(statusHistoriesData)
        } catch (e) {
          console.error("Error parsing status histories JSON:", e)
        }
      }
      
      if (locationsData) {
        try {
          this.locationsValue = JSON.parse(locationsData)
        } catch (e) {
          console.error("Error parsing locations JSON:", e)
        }
      }
    }
    
    this.loadGoogleMapsAPI()
  }

  switchTab(event) {
    const targetTab = event.currentTarget.dataset.tab
    
    // Update tab buttons
    this.element.querySelectorAll('.tab-button').forEach(button => {
      button.classList.remove('border-blue-500', 'text-blue-600')
      button.classList.add('border-transparent', 'text-gray-500')
    })
    
    event.currentTarget.classList.remove('border-transparent', 'text-gray-500')
    event.currentTarget.classList.add('border-blue-500', 'text-blue-600')
    
    // Show/hide tab content
    this.element.querySelectorAll('.tab-content').forEach(content => {
      content.classList.add('hidden')
    })
    
    const targetContent = this.element.querySelector(`#${targetTab}`)
    if (targetContent) {
      targetContent.classList.remove('hidden')
    }
  }

  centerOnStatus(event) {
    const latitude = event.currentTarget.dataset.latitude
    const longitude = event.currentTarget.dataset.longitude
    const status = event.currentTarget.dataset.status
    
    this.centerOnStatus(latitude, longitude, status)
    
    // Add visual feedback
    event.currentTarget.classList.add('bg-blue-50')
    setTimeout(() => {
      event.currentTarget.classList.remove('bg-blue-50')
    }, 1000)
  }

  highlightLocation(event) {
    const latitude = event.currentTarget.dataset.latitude
    const longitude = event.currentTarget.dataset.longitude
    const index = parseInt(event.currentTarget.dataset.index)
    
    this.highlightLocation(latitude, longitude, index)
    
    // Add visual feedback
    event.currentTarget.classList.add('bg-blue-50')
    setTimeout(() => {
      event.currentTarget.classList.remove('bg-blue-50')
    }, 1000)
  }

  // Map functionality
  loadGoogleMapsAPI() {
    if (window.google && window.google.maps) {
      this.initializeMap()
      return
    }
    debugger;
    console.log(this.apiKeyValue);
    const script = document.createElement('script')
    script.src = `https://maps.googleapis.com/maps/api/js?key=${this.apiKeyValue}&callback=initDetailsMapCallback&libraries=geometry`
    script.async = true
    script.defer = true
    script.onerror = () => this.handleMapError('Failed to load Google Maps API')
    
    // Set up global callback
    window.initDetailsMapCallback = () => this.initializeMap()
    window.gm_authFailure = () => this.handleMapError('Invalid API key or authentication failed')
    
    document.head.appendChild(script)
  }

  initializeMap() {
    try {
      if (!window.google || !window.google.maps) {
        this.handleMapError('Google Maps API not loaded properly')
        return
      }

      this.map = new google.maps.Map(this.mapTarget, {
        zoom: 6,
        center: { lat: 36.182487, lng: -86.469841 },
        mapTypeId: 'roadmap',
        styles: [
          {
            featureType: 'poi',
            elementType: 'labels',
            stylers: [{ visibility: 'off' }]
          }
        ]
      })

      // Wait for map to be ready
      google.maps.event.addListenerOnce(this.map, 'idle', () => {
        this.setupMapContent()
      })

    } catch (error) {
      console.error('Error initializing map:', error)
      this.handleMapError('Error initializing map')
    }
  }

  setupMapContent() {
    this.createPolylines()
    this.addStatusMarkers()
    this.addLocationMarkers()
    this.addCurrentLocationMarker()
    this.fitMapBounds()
  }

  createPolylines() {
    if (!this.locationsValue || this.locationsValue.length === 0) return

    const path = this.locationsValue.map(loc => ({
      lat: parseFloat(loc.latitude),
      lng: parseFloat(loc.longitude)
    }))

    // Create the main route polyline with directional arrows
    this.polyline = new google.maps.Polyline({
      path: path,
      geodesic: true,
      strokeColor: '#2563eb',
      strokeOpacity: 0.9,
      strokeWeight: 5,
      zIndex: 10,
      icons: [
        { icon: { path: google.maps.SymbolPath.FORWARD_CLOSED_ARROW, scale: 6, strokeColor: '#1e40af', fillColor: '#1e40af', fillOpacity: 1, strokeWeight: 3 }, offset: '20%' },
        { icon: { path: google.maps.SymbolPath.FORWARD_CLOSED_ARROW, scale: 6, strokeColor: '#1e40af', fillColor: '#1e40af', fillOpacity: 1, strokeWeight: 3 }, offset: '40%' },
        { icon: { path: google.maps.SymbolPath.FORWARD_CLOSED_ARROW, scale: 6, strokeColor: '#1e40af', fillColor: '#1e40af', fillOpacity: 1, strokeWeight: 3 }, offset: '60%' },
        { icon: { path: google.maps.SymbolPath.FORWARD_CLOSED_ARROW, scale: 6, strokeColor: '#1e40af', fillColor: '#1e40af', fillOpacity: 1, strokeWeight: 3 }, offset: '80%' }
      ]
    })
    this.polyline.setMap(this.map)
    
    // Add a white background polyline for better visibility
    const backgroundPolyline = new google.maps.Polyline({
      path: path,
      geodesic: true,
      strokeColor: '#ffffff',
      strokeOpacity: 1.0,
      strokeWeight: 7,
      zIndex: 9
    })
    backgroundPolyline.setMap(this.map)
  }

  addStatusMarkers() {
    if (!this.statusHistoriesValue) return

    this.statusMarkers = []
    this.statusHistoriesValue.forEach((status) => {
      const marker = new google.maps.Marker({
        position: { lat: parseFloat(status.latitude), lng: parseFloat(status.longitude) },
        map: this.map,
        title: status.status + ' - ' + status.address,
        icon: {
          path: google.maps.SymbolPath.CIRCLE,
          scale: 10,
          fillColor: this.getStatusColor(status.status),
          fillOpacity: 0.9,
          strokeColor: '#ffffff',
          strokeWeight: 3
        },
        zIndex: 10
      })

      const infoWindow = new google.maps.InfoWindow({
        content: `
          <div class="p-2">
            <h3 class="font-semibold text-sm">${status.status}</h3>
            <p class="text-xs text-gray-600">${status.address}</p>
            <p class="text-xs text-gray-500 mt-1">${new Date(status.changed_at).toLocaleString()}</p>
            ${status.notes ? `<p class="text-xs text-gray-500 mt-1 italic">${status.notes}</p>` : ''}
          </div>
        `
      })

      marker.addListener('click', () => {
        infoWindow.open(this.map, marker)
      })

      this.statusMarkers.push(marker)
    })
  }

  addLocationMarkers() {
    if (!this.locationsValue) return

    this.locationMarkers = []
    this.locationsValue.forEach((location, index) => {
      const marker = new google.maps.Marker({
        position: { lat: parseFloat(location.latitude), lng: parseFloat(location.longitude) },
        map: this.map,
        title: 'Location ' + (index + 1) + ' - ' + location.address,
        icon: {
          path: google.maps.SymbolPath.CIRCLE,
          scale: 4,
          fillColor: '#6b7280',
          fillOpacity: 0.7,
          strokeColor: '#ffffff',
          strokeWeight: 1
        }
      })

      const infoWindow = new google.maps.InfoWindow({
        content: `
          <div class="p-2">
            <h3 class="font-semibold text-sm">Location ${index + 1}</h3>
            <p class="text-xs text-gray-600">${location.address}</p>
            <p class="text-xs text-gray-500 mt-1">${new Date(location.recorded_at * 1000).toLocaleString()}</p>
            ${location.speed ? `<p class="text-xs text-gray-500">Speed: ${location.speed} km/h</p>` : ''}
          </div>
        `
      })

      marker.addListener('click', () => {
        infoWindow.open(this.map, marker)
      })

      this.locationMarkers.push(marker)
    })
  }

  addCurrentLocationMarker() {
    if (!this.locationsValue || this.locationsValue.length === 0) return

    const latestLocation = this.locationsValue[this.locationsValue.length - 1]
    this.currentLocationMarker = new google.maps.Marker({
      position: { lat: parseFloat(latestLocation.latitude), lng: parseFloat(latestLocation.longitude) },
      map: this.map,
      title: 'Current Location',
      icon: {
        path: google.maps.SymbolPath.CIRCLE,
        scale: 12,
        fillColor: '#10b981',
        fillOpacity: 1,
        strokeColor: '#ffffff',
        strokeWeight: 4
      },
      zIndex: 20
    })
    
    // Add a pulsing animation effect
    new google.maps.Marker({
      position: { lat: parseFloat(latestLocation.latitude), lng: parseFloat(latestLocation.longitude) },
      map: this.map,
      icon: {
        path: google.maps.SymbolPath.CIRCLE,
        scale: 16,
        fillColor: '#10b981',
        fillOpacity: 0.3,
        strokeColor: '#10b981',
        strokeWeight: 2
      },
      zIndex: 19
    })
  }

  fitMapBounds() {
    const bounds = new google.maps.LatLngBounds()
    
    // Add all location points to bounds
    if (this.locationsValue && this.locationsValue.length > 0) {
      this.locationsValue.forEach(loc => {
        bounds.extend({ lat: parseFloat(loc.latitude), lng: parseFloat(loc.longitude) })
      })
    }
    
    // Add all status history points to bounds
    if (this.statusHistoriesValue && this.statusHistoriesValue.length > 0) {
      this.statusHistoriesValue.forEach(status => {
        bounds.extend({ lat: parseFloat(status.latitude), lng: parseFloat(status.longitude) })
      })
    }
    
    // Only fit bounds if we have points
    if (!bounds.isEmpty()) {
      this.map.fitBounds(bounds)
    } else {
      // Fallback to a default center if no points
      this.map.setCenter({ lat: 36.182487, lng: -86.469841 })
      this.map.setZoom(6)
    }
  }

  // Map interaction methods
  centerOnStatus(latitude, longitude, status) {
    if (this.map) {
      const position = { lat: parseFloat(latitude), lng: parseFloat(longitude) }
      this.map.setCenter(position)
      this.map.setZoom(12)
    }
  }

  highlightLocation(latitude, longitude, index) {
    if (this.map && this.locationMarkers && this.locationMarkers[index]) {
      const position = { lat: parseFloat(latitude), lng: parseFloat(longitude) }
      this.map.setCenter(position)
      this.map.setZoom(12)
      
      // Highlight the specific marker
      this.locationMarkers[index].setIcon({
        path: google.maps.SymbolPath.CIRCLE,
        scale: 8,
        fillColor: '#ef4444',
        fillOpacity: 1,
        strokeColor: '#ffffff',
        strokeWeight: 2
      })
      
      // Reset after 2 seconds
      setTimeout(() => {
        this.locationMarkers[index].setIcon({
          path: google.maps.SymbolPath.CIRCLE,
          scale: 4,
          fillColor: '#6b7280',
          fillOpacity: 0.7,
          strokeColor: '#ffffff',
          strokeWeight: 1
        })
      }, 2000)
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

