
class RidesController < ApplicationController
    include RouteDataConcern

    # GET driver/:driver_id/rides
    def index
        @driver = Driver.find(params[:driver_id])

        # TODO: query for rides paginated

        @rides = Ride.order(id: :desc)

        rides = fetch_ride_data(@driver, @rides)

        # sort by rides.score

        render json: rides
    end
  
    # GET /rides/:id
    def show
        @ride = Ride.find(params[:id])
        render json: @ride
    end
  
    # POST /rides
    def create
        begin
            @ride = Ride.create!(ride_params)
        rescue => e
            render json: { error: e.message }, status: :bad_request
            return
        end

        # Enqueue Sidekiq job to fetch ride data
        FetchRouteDurationWorker.perform_async(@ride.id)

        render json: @ride, status: :created, location: @ride
    end
  
    # DELETE /rides/:id
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
