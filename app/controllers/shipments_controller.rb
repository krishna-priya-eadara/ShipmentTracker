class ShipmentsController < ApplicationController
  def index
    @shipments = Shipment.all.order(created_at: :desc)
  end

  def show
    @shipment = Shipment.find_by(shipment_identifier: params[:id])
    if @shipment.nil?
      redirect_to shipments_path, alert: 'Shipment not found'
    end
  end

  def dashboard
    @shipments = Shipment.all.order(created_at: :desc)
  end

  def start_simulation
    @shipment = find_shipment_by_id_or_identifier(params[:id])
    return redirect_to shipments_path, alert: 'Shipment not found' unless @shipment

    # Start simulation in background
    GpsSimulatorService.new(@shipment).simulate_route(60, 30) # 60 minutes, 30-second intervals
    
    redirect_to @shipment, notice: "GPS simulation started for #{@shipment.shipment_identifier}"
  end

  def stop_simulation
    @shipment = find_shipment_by_id_or_identifier(params[:id])
    return redirect_to shipments_path, alert: 'Shipment not found' unless @shipment

    # In a real implementation, you'd need to track running simulations
    redirect_to @shipment, notice: "GPS simulation stopped for #{@shipment.shipment_identifier}"
  end

  def simulate_update
    @shipment = find_shipment_by_id_or_identifier(params[:id])
    return redirect_to shipments_path, alert: 'Shipment not found' unless @shipment

    # Simulate a single location update
    GpsSimulatorService.new(@shipment).simulate_single_update
    
    redirect_to @shipment, notice: "Simulated location update for #{@shipment.shipment_identifier}"
  end

  private

  def find_shipment_by_id_or_identifier(id)
    # Try to find by ID first (numeric), then by shipment_identifier
    if id.match?(/^\d+$/)
      Shipment.find_by(id: id)
    else
      Shipment.find_by(shipment_identifier: id)
    end
  end
end
