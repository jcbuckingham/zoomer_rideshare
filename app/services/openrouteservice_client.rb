require 'httparty'
require 'json'

# TODO: raise errors instead of returning nil
class OpenrouteserviceClient
    def initialize
        @api_key = ENV['OPENROUTESERVICE_API_KEY']
        Rails.logger.info("api_key: #{@api_key}")
        @matrix_endpoint = ENV['OPENROUTESERVICE_MATRIX_ENDPOINT']
    end

    def get_matrix_data(driver, rides)
        # The first location in the set will be the driver's home_address
        location_pairs = [driver.home_address.split(",").map(&:to_f)]

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
            'resolve_locations': false, # skipping closest street name data
            'units': 'mi' # in miles
        }

        headers = {
            'Content-Type' => 'application/json',
            'Authorization' => @api_key,
            'Accept' => 'application/json',
        }

        response = HTTParty.post(
            @matrix_endpoint,
            body: request_payload.to_json,
            headers: headers
        )

        JSON.parse(response.body)
    rescue HTTParty::Error, JSON::ParserError => e
        # Handle API errors
        Rails.logger.warn("Error fetching route duration: #{e}")
        raise e
    end

end
