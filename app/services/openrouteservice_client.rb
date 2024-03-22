require 'rest-client'
require 'json'

# TODO: raise errors instead of returning nil
class OpenrouteserviceClient
    def initialize
        @api_key = ENV['OPENROUTESERVICE_API_KEY']
        @matrix_endpoint = ENV['OPENROUTESERVICE_MATRIX_ENDPOINT']
    end

    def get_matrix_duration(driver, rides)
        # The first location in the set will be the driver's home_address
        location_pairs = [driver.home_address.split(",").map(&:to_f)]
        rides = Ride.order(id: :desc)

        # Then locations are added in pairs: the ride's start_address and destination_address
        # The durations will be returned in the same order, so to process the result, we will also
        # rely on these pairings.
        rides.each do |ride|
            location_pairs << ride.start_address.split(",").map(&:to_f)
            location_pairs << ride.destination_address.split(",").map(&:to_f)
        end

        request_payload = {
            'locations' => location_pairs,
            'metrics' => ['duration', 'distance'], # specifies the data type to fetch
        }

        response = RestClient.post(
            @matrix_endpoint,
            request_payload.to_json,
            headers: { 'Content-Type' => 'application/json', 'Authorization' => @api_key }
        )

        JSON.parse(response.body)
    rescue RestClient::ExceptionWithResponse => e
        # Handle API errors
        Rails.logger.warn("Error fetching route duration: #{e}")
        nil
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
        durations.each_with_index do |ride_durations, i|
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

    # def get_route_duration(start_coords, end_coords)
    #     url = "#{@directions_endpoint}?api_key=#{@api_key}&start=#{start_coords}&end=#{end_coords}"
    #     response = RestClient.get(url)
    #     data = JSON.parse(response.body)
    #     # Extract duration from the response
    #     begin
    #         duration = data['features'][0]['properties']['summary']['duration']
    #     rescue NoMethodError, IndexError => e
    #         Rails.logger.warn("Openrouteservice json response received in unexpected format: #{e}")
    #         return nil
    #     end
        
    #     duration # Return duration in seconds
    # rescue RestClient::ExceptionWithResponse => e
    #     # Handle API errors
    #     Rails.logger.warn("Error fetching route duration: #{e}")
    #     nil
    # end
end
