
class RidesController < ApplicationController
    include RouteDataConcern

    # GET driver/:driver_id/rides
    def index
        @driver = Driver.find(params[:driver_id])

        cache_key = "rides_for_driver_#{params[:driver_id]}"
        cached_ride_ids = Rails.cache.read(cache_key)

        if cached_ride_ids
            Rails.logger.info("Cache hit on key #{cache_key}")
            # If the cached rides exist, paginate them and return the paginated response
            paginated_rides = paginate_cached_ride_ids(cached_ride_ids)
            render json: paginated_rides
            return
        end

        Rails.logger.info("Cache miss on key #{cache_key}")
        @rides = Ride.all

        begin
            rides = fetch_ride_data(@driver, @rides)
            ride_ids = rides.map(&:id)
        rescue => e
            Rails.logger.error("Backtrace: #{e.backtrace.join("\n")}")
            render json: { error: "Openrouteservice error - #{e.message}" }, status: :service_unavailable
            return
        end

        # Cache the paginated response and expire it in 5 minutes so the driver can see new rides without much delay
        Rails.cache.write(cache_key, ride_ids, expires_in: 5.minutes)

        # Paginate the cached rides and return the paginated response
        paginated_rides = paginate_cached_rides(rides)
        render json: paginated_rides
    end

    def paginate_cached_ride_ids(ride_ids)
        page = params[:page].to_i > 0 ? params[:page].to_i : 1
        per_page = params[:per_page].to_i > 0 ? params[:per_page].to_i : 10
    
        total_rides = ride_ids.count
        offset = (page.to_i - 1) * per_page
        paginated_ride_ids = ride_ids[offset, per_page]

        rides = Ride.where(id: paginated_ride_ids)

        # Preserve the order of rides based on the cached order
        # Create a hash to map IDs to records for efficient lookup
        ride_hash = rides.index_by(&:id)

        # Sort the records based on the order of IDs
        paginated_rides = paginated_ride_ids.map { |id| ride_hash[id] }
    
        {
            total_rides: total_rides,
            page: page.to_i,
            per_page: per_page.to_i,
            rides: paginated_rides
        }
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
