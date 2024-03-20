class RidesController < ApplicationController

    # GET /rides
    def index
        @rides = Ride.all
        render json: @rides
    end
  
    # GET /rides/1
    def show
        @ride = Ride.find(params[:id])
        render json: @ride
    end
  
    # POST /rides
    def create
        begin
            @ride = Ride.create!(ride_params)
            render json: @ride, status: :created, location: @ride
        rescue => e
            render json: { error: e.message }, status: :bad_request
        end
    end
  
    # DELETE /rides/1
    def destroy
        @ride = Ride.find(params[:id])
        @ride.destroy if @ride
    end
  
    private
    
    # Only allow a list of trusted parameters through.
    def ride_params
        params.require(:ride).permit(:start_address, :destination_address)
    end
end
