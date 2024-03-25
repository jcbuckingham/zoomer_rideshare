require 'httparty'
require 'json'

class InvalidAddressError < StandardError
end

class OpenrouteserviceClient
    def initialize
        @api_key = ENV['OPENROUTESERVICE_API_KEY']
        @endpoint = ENV['OPENROUTESERVICE_ENDPOINT']
    end

    def get_matrix_data(driver, rides)
        # The first location in the set will be the driver's home_coords
        location_pairs = [ driver.home_coords.split(",").map { |coords| coords.to_f } ]

        # Then locations are added in pairs: the ride's start_coords and destination_coords
        # The durations will be returned in the same order, so to process the result, we will also
        # rely on these pairings.
        rides.each do |ride|
            # If coords are nil, the job to fetch coords has not run successfully. 
            # Skip since we don't have enough data for a ride without coords.
            next if ride.start_coords.nil? || ride.destination_coords.nil?

            location_pairs << ride.start_coords.split(",").map { |coords| coords.to_f }
            location_pairs << ride.destination_coords.split(",").map { |coords| coords.to_f }
        end

        request_payload = {
            'locations' => location_pairs,
            'metrics' => ['duration', 'distance'], # Specifies the data type to fetch
            'resolve_locations': false,            # Skipping closest street name data
            'units': 'mi'                          # In miles
        }

        headers = {
            'Content-Type' => 'application/json',
            'Authorization' => @api_key,
            'Accept' => 'application/json',
        }

        url = "#{@endpoint}/v2/matrix/driving-car"

        response = HTTParty.post(
            url,
            body: request_payload.to_json,
            headers: headers
        )

        JSON.parse(response.body)
    rescue HTTParty::Error, JSON::ParserError => e
        Rails.logger.error("Error fetching route durations and distances: #{e}")
        raise e
    end

    # Fetches a set of coords based on a physical address on Driver or Ride creation
    def convert_address_to_coords(address)
        url = "#{@endpoint}/geocode/search?api_key=#{@api_key}&text=#{CGI.escape(address)}"
        
        response = HTTParty.get(url)
        
        data = JSON.parse(response.body)

        if data['features'] && !data['features'].empty?
            coordinates = data['features'][0]['geometry']['coordinates']
            latitude = coordinates[1]
            longitude = coordinates[0]
            return "#{longitude},#{latitude}"
        end
        
        raise InvalidAddressError
    rescue HTTParty::Error, JSON::ParserError => e
        Rails.logger.warn("Error converting address to coords: #{e}")
        raise e
    end
end
