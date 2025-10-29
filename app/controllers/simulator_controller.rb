class SimulatorController < ApplicationController
  def index
    @shipments = Shipment.all.order(created_at: :desc)
    @running_simulations = get_running_simulations
  end

  def start_all
    # Start simulation for all shipments
    Shipment.all.each do |shipment|
      Thread.new do
        GpsSimulatorService.new(shipment).simulate_route(60, 30)
      end
    end
    
    redirect_to simulator_path, notice: "Started GPS simulation for all shipments"
  end

  def stop_all
    # In a real implementation, you'd need to track and stop running simulations
    redirect_to simulator_path, notice: "Stopped all GPS simulations"
  end

  private

  def get_running_simulations
    # In a real implementation, you'd track running simulations in Redis or database
    []
  end
end
