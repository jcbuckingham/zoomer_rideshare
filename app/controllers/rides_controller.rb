
class RidesController < ApplicationController
    include RouteDataConcern

    # GET driver/:driver_id/rides
    def index
        @driver = Driver.find(params[:driver_id])

        cache_key = "rides_driver_#{params[:driver_id]}"
        cached_rides = Rails.cache.read(cache_key)

        if cached_rides
            Rails.logger.info("Cache hit on key #{cache_key}")
            # If the cached rides exist, paginate them and return the paginated response
            paginated_rides = paginate_cached_rides(cached_rides)
            render json: paginated_rides
            return
        end

        Rails.logger.info("Cache miss on key #{cache_key}")
        @rides = Ride.order(id: :desc)

        begin
            rides = fetch_ride_data(@driver, @rides)
        rescue => e
            Rails.logger.error("Backtrace: #{e.backtrace.join("\n")}")
            render json: { error: "Openrouteservice error - #{e.message}" }, status: :service_unavailable
            return
        end

        # Cache the paginated response
        Rails.cache.write(cache_key, rides)

        # Paginate the cached rides and return the paginated response
        paginated_rides = paginate_cached_rides(rides)
        render json: paginated_rides
    end

    def paginate_cached_rides(rides_data)
        page = params[:page].to_i > 0 ? params[:page].to_i : 1
        per_page = params[:per_page].to_i > 0 ? params[:per_page].to_i : 10

    
        total_rides = rides_data.count

        paginated_rides = rides_data.slice((page.to_i - 1) * per_page, per_page)
    
        {
          total_rides: total_rides,
          page: page.to_i,
          per_page: per_page.to_i,
          rides: paginated_rides
        }
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
