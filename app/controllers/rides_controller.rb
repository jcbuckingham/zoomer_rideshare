class RidesController < ApplicationController
    include PaginationService

    # GET /rides?driver_id=:driver_id
    def index
        unless params[:driver_id]
            render json: { error: "Param driver_id is required" }, status: :bad_request
            return
        end

        begin
            @driver = Driver.find(params[:driver_id])
        rescue ActiveRecord::RecordNotFound
            render json: { error: "Driver not found" }, status: :not_found
            return
        end

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
        rescue => e
            render json: { error: "An unexpected error occurred: #{e.message}", status: :internal_server_error }
            return
        end

        # Paginate the Rides and return the paginated response
        paginated_rides_response = PaginationService.paginate_rides(rides, params[:page], params[:per_page])
        render json: paginated_rides_response
    end

    # GET /rides/:id
    def show
        begin
            @ride = Ride.find(params[:id])
        rescue ActiveRecord::RecordNotFound
            render json: { error: "Ride not found" }, status: :not_found
            return
        end
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

        # Enqueue Sidekiq job to fetch ride coords offline
        FetchAddressCoordsWorker.perform_async("Ride", @ride.id)

        render json: @ride, status: :created, location: @ride
    end
  
    # DELETE /rides/:id
    def destroy
        begin
            @ride = Ride.find(params[:id])
        rescue => e
            render json: { error: e.message }, status: :bad_request
            return
        end
        @ride.destroy if @ride
    end
  
    private
    
    # Only allow a list of trusted parameters through.
    def ride_params
        params.require(:ride).permit(:start_address, :destination_address)
    end
end
