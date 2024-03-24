module PaginationService
    def self.get_paginated_rides_response(driver, page_param, per_page_param)
        # First check the cache for pre-ordered Ride data and return one page of results
        paginated_cached_result = PaginationService.check_driver_cache(driver.id, page_param, per_page_param)
        return paginated_cached_result if paginated_cached_result

        # If there is a cache miss:
        # Fetch and score rides for the driver based on fresh Openrouteservice data and return Rides ordered by score.
        rides = Ride.prepare_data(driver)

        # Paginate the Rides and return the paginated response
        PaginationService.paginate_rides(rides, page_param, per_page_param)
    end

    def self.check_driver_cache(driver_id, page_param, per_page_param)
        cache_key = "rides_for_driver_#{driver_id}"
        cached_ride_ids = Rails.cache.read(cache_key)

        if cached_ride_ids
            Rails.logger.info("Cache hit on key #{cache_key}")
            # If the cached rides exist, get the ordered paginated rides
            return paginate_cached_ride_ids(cached_ride_ids, page_param, per_page_param)
        end

        Rails.logger.info("Cache miss on key #{cache_key}")
        nil
    end

    # This method performs pagination on all system Rides that have been sorted based on score. 
    # It is called when there is a cache miss.
    # 
    # Future optimization: this method could easily be made class agnostic 
    def self.paginate_rides(rides_data, page_param, per_page_param)
        # Get pagination params or defaults
        page = page_param.to_i > 0 ? page_param.to_i : 1
        per_page = per_page_param.to_i > 0 ? per_page_param.to_i : 10
    
        total_rides = rides_data.count
    
        # Get the paginated slice of records from the in memory Rides that have been sorted based on score
        paginated_rides = rides_data.slice((page.to_i - 1) * per_page, per_page)

        {
            total_rides: total_rides,
            page: page.to_i,
            per_page: per_page.to_i,
            rides: paginated_rides
        }
    end

    # This method takes an array of pre-ordered ride_ids from the cache, selects an offset
    # subarray based on pagination parameters and uses it to query for the associate Ride 
    # records in the database.  This allows the cache to store a record of all Rides in the 
    # system for each driver sorted by score, but with minimal overhead: it is just an array of ids.  
    # 
    # Future optimization could be made if we could filter Rides by other properties that we don't 
    # currently have, like segment to see if a ride is in the general vicinity of the user, status
    # to filter out completed rides, or date to filter out rides that are past or too far in the future.
    def self.paginate_cached_ride_ids(cached_ride_ids, page_param, per_page_param)
        # Get pagination params or defaults
        page = page_param.to_i > 0 ? page_param.to_i : 1
        per_page = per_page_param.to_i > 0 ? per_page_param.to_i : 10
    
        total_rides = cached_ride_ids.count
        offset = (page.to_i - 1) * per_page
        # Get a subarray based on the offset and per_page count
        paginated_ride_ids = cached_ride_ids[offset, per_page]

        # Fetch all rides in the subarray only.  If the per_page count is 10, this will fetch <= 10 Rides
        rides = Ride.where(id: paginated_ride_ids)

        # Preserve the order of rides based on the cached order:
        # First create a hash to map ids to records for efficient lookup
        ride_hash = rides.index_by(&:id)

        # Then sort the records based on the order of the subarray ids since they are pre-ordered based on score
        paginated_rides = paginated_ride_ids.map { |id| ride_hash[id] }
    
        {
            total_rides: total_rides,
            page: page.to_i,
            per_page: per_page.to_i,
            rides: paginated_rides
        }
    end
end