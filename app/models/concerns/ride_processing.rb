module RideProcessing
    extend ActiveSupport::Concern
  
    class_methods do
        # Called from the RideController, fetches Ride records, 
        def prepare_data(driver)
            # Note: Loading a whole table is not a good practice. I am doing so here for simplicity.  With more time I would introduce fields to filter Rides on and also process records in batches and store 
            # the score results in the cache as I went since I have a mechanism to return paginated results from the cache already.
            rides = Ride.all

            # if there are no Rides, skip processing and caching
            return [] if rides.empty?
    
            driver_rides = fetch_ride_data(driver, rides)
            ranked_rides = calculate_and_rank_scores(driver_rides)

            ride_ids = ranked_rides.pluck(:id)

            # Cache the paginated response and expire it in 5 minutes so the driver can see new rides without much delay
            cache_key = "rides_for_driver_#{driver.id}"
            Rails.cache.write(cache_key, ride_ids, expires_in: 5.minutes) unless ride_ids.empty?
    
            ranked_rides
        end
    
        # Uses the OpenrouteserviceClient to fetch matrix data on all locations, traverses the matrix for necessary
        # details, and uses RideScoreCalculator to calculate and rank all scores.
        def fetch_ride_data(driver, rides)
            client = OpenrouteserviceClient.new
            json_data = client.get_matrix_data(driver, rides)
            
            driver_rides = process_matrix_route_data(json_data["durations"], json_data["distances"], rides)
        end

        # Calculates all scores and add them to the DriverRides then sorts the DriverRides.rides_info by score
        def calculate_and_rank_scores(driver_rides)
            calculator = RideScoreCalculator.new(driver_rides)
            calculator.calculate_scores

            driver_rides.sort_rides_by_score!
            driver_rides.rides_info.pluck(:ride)
        end
    
        # The result received from Openrouteservice's matrix endpoint gives all the durations
        # required in one API call, so it severely cuts down on network calls, but we need to 
        # traverse the matrix programatically in order to discover the relevant data for the driver's
        # commute to each ride and the duration from the ride's start_coords to its destination_coords.
        #
        # The logic is as follows:
        def process_matrix_route_data(durations, distances, rides)
            # Collect results in the format [{commute: <duration>, ride: <duration>},...] for each ride.
            driver_rides = DriverRides.new(rides_info=[])

            # As stated in OpenrouteserviceClient.get_matrix_data(), the first element in the 
            # durations array from Openrouteservice is an array of the durations from the driver's 
            # home_coords to all rides' start_coordses.
            driver_to_start_coords_durations = durations[0]
            driver_to_start_coords_distances = distances[0]

            # Creates a separate index for iterating through the rides records
            ride_index = 0
    
            # The rest of the elements in durations are in pairs, first a ride's start_coords to all 
            # other addresses, and then a ride's destination_coords to all other addresses.  For our 
            # purposes, we only care about the commute duration (driver's home_coords to ride's start_coords)
            # and the ride duration (ride's start_coords to its destination_coords), so most of the 
            # matrix data is ignored.
            durations.zip(distances).each_with_index do |ride_data, i|
                # Skip the data on even elements because they are durations FROM destination_coordses
                # and skip the data on the first element because it is the driver's home_coords which we 
                # already captured.
                next if i.even? || i.zero?
        
                ride_info = RideInfo.new(
                    commute_distance: driver_to_start_coords_distances[i],
                    commute_duration: driver_to_start_coords_durations[i],
                    ride_distance: ride_data.last[i + 1],
                    ride_duration: ride_data.first[i + 1],
                    ride: rides[ride_index]
                )
                # Append the data to result and increment ride_index
                driver_rides.rides_info << ride_info
                ride_index += 1
            end
    
            # Return DriverRides object with all ride data for the driver
            driver_rides
        end
    end
  
    class DriverRides < Struct.new(
        :rides_info
    )
        def sort_rides_by_score!
            rides_info.sort_by! { |ride_info| -ride_info.ride_score }
        end
    end
  
    class RideInfo < Struct.new(
        :commute_distance, 
        :commute_duration, 
        :ride_distance, 
        :ride_duration,
        :ride,
        :ride_score
    )
    end
end
  