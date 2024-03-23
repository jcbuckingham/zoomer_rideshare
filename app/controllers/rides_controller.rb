
class RidesController < ApplicationController
    include PaginationService

    # GET /rides
    def index
        @driver = Driver.find(params[:driver_id])

        # First check the cache for pre-ordered Ride data and return one page of results
        paginated_cached_result = PaginationService.check_driver_cache(@driver.id, params[:page], params[:per_page])
        if paginated_cached_result
            render json: paginated_cached_result
            return
        end

        # If there is a cache miss:
        # Fetch and score rides for the driver based on fresh Openrouteservice data and return Rides ordered by score.
        begin
            rides = Ride.prepare_data(@driver)
        rescue HTTParty::Error, JSON::ParserError => e
            render json: { error: "Ride information could not be fetched.", status: :service_unavailable }
            return
        end

        # Paginate the Rides and return the paginated response
        paginated_rides_response = PaginationService.paginate_rides(rides, params[:page], params[:per_page])
        render json: paginated_rides_response
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

        # Enqueue Sidekiq job to fetch ride coords
        FetchAddressCoordsWorker.perform_async("Ride", @ride.id)

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
