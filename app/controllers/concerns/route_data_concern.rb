module RouteDataConcern
    extend ActiveSupport::Concern
  
    class DriverRides < Struct.new(:routes_info)
        def sort_routes_by_score!
            # Sort the routes_info array by ride_score in descending order
            routes_info.sort_by! { |route_info| -route_info.ride_score }
          end
    end

    class RouteInfo < Struct.new(
        :commute_distance, 
        :commute_duration, 
        :ride_distance, 
        :ride_duration,
        :ride,
        :ride_score
    )
    end

    def fetch_ride_data(driver, rides)
        client = OpenrouteserviceClient.new
        json_data = client.get_matrix_duration(driver, rides)
        driver_rides = process_matrix_route_data(json_data["duration"], json_data["distance"], rides)
        # Calculate all scores and add them to the DriverRides
        RideScoreCalculator.new(ride, driver_rides)

        # Sort the DriverRides.routes_info by score
        driver_rides.sort_routes_by_score!

        result = driver_rides.routes_info.map {|route_info| route_info.ride }
    end

    # The result received from Openrouteservice's matrix endpoint gives all the durations
    # required in one API call, so it severely cuts down on network calls, but we need to 
    # traverse the matrix programatically in order to discover the durations for the driver's
    # commute to each ride and the duration from the ride's start_address to its destination_address.
    #
    # The logic is as follows:
    def process_matrix_route_data(durations, distances, rides)
        # Collect results in the format [{commute: <duration>, ride: <duration>},...] for each ride.
        result = []
        driver_rides = DriverRides.new(routes_info=[])

        # As stated in OpenrouteserviceClient.get_matrix_duration(), the first element in the 
        # durations array from Openrouteservice is an array of the durations from the driver's 
        # home_address to all rides' start_addresses.
        driver_to_start_address_durations = durations[0]
        driver_to_start_address_distances = distances[0]
      
        # Creates a separate index for iterating through the rides records
        # TODO: enumerable?
        ride_index = 0

        # The rest of the elements in durations are in pairs, first a ride's start_address to all 
        # other addresses, and then a ride's destination_address to all other addresses.  For our 
        # purposes, we only care about the commute duration (driver's home_address to ride's start_address)
        # and the ride duration (ride's start_address to its destination_address), so most of the 
        # matrix data is ignored.

        durations.zip(distances).each_with_index do |ride_data, i|
            # Skip the data on even elements because they are durations FROM destination_addresses
            # and skip the data on the first element because it is the driver's home_address which we 
            # already captured.
            next if i.even? || i.zero?
        
            # For each set of ride start_address durations, find the corresponding commute duration
            # from the driver's home_address array and find the ride duration to the destination.
            # ride_data = {
            #     commute: driver_to_start_address_durations[i],
            #     ride: ride_data.first[i + 1]
            # }
            route_info = RouteInfo.new(
                commute_distance: driver_to_start_address_distances[i],
                commute_duration: driver_to_start_address_durations[i],
                ride_distance: ride_data.last[i + 1],
                ride_duration: ride_data.first[i + 1],
                ride: rides[ride_index]
            )
            # Append the data to result
            driver_rides.routes_info << route_info

            # increment ride index
            ride_index += 1
        end
      
        # Return result
        driver_rides
    end

    # The result received from Openrouteservice's matrix endpoint gives all the durations
    # required in one API call, so it severely cuts down on network calls, but we need to 
    # traverse the matrix programatically in order to discover the durations for the driver's
    # commute to each ride and the duration from the ride's start_address to its destination_address.
    #
    # The logic is as follows:
    def process_matrix_durations(durations)
        # Collect results in the format [{commute: <duration>, ride: <duration>},...] for each ride.
        result = []

        # As stated in OpenrouteserviceClient.get_matrix_duration(), the first element in the 
        # durations array from Openrouteservice is an array of the durations from the driver's 
        # home_address to all rides' start_addresses.
        driver_to_start_address_durations = durations[0]
      
        # The rest of the elements in durations are in pairs, first a ride's start_address to all 
        # other addresses, and then a ride's destination_address to all other addresses.  For our 
        # purposes, we only care about the commute duration (driver's home_address to ride's start_address)
        # and the ride duration (ride's start_address to its destination_address), so most of the 
        # matrix data is ignored.
        durations.each_with_index do |ride_durations, ride_distances, i|
            # Skip the data on even elements because they are durations FROM destination_addresses
            # and skip the data on the first element because it is the driver's home_address which we 
            # already captured.
            next if i.even? || i.zero?
        
            # For each set of ride start_address durations, find the corresponding commute duration
            # from the driver's home_address array and find the ride duration to the destination.
            ride_data = {
                commute: driver_to_start_address_durations[i],
                ride: ride_durations[i + 1]
            }
            # Append the data to result
            result << ride_data
        end
      
        # Return result
        result
    end
end
  