require 'rest-client'

# TODO: raise errors instead of returning nil
class OpenrouteserviceClient
    def initialize(api_key)
        @api_key = ENV['OPENROUTESERVICE_API_KEY']
        @directions_endpoint = ENV['OPENROUTESERVICE_DIRECTIONS_ENDPOINT']
    end

    def get_route_duration(start_coords, end_coords)
        url = "#{@directions_endpoint}?api_key=#{@api_key}&start=#{start_coords}&end=#{end_coords}"
        response = RestClient.get(url, accept: 'application/json')
        data = JSON.parse(response.body)
        
        # Extract duration from the response
        begin
            duration = data['features'][0]['properties']['summary']['duration']
        rescue NoMethodError, IndexError => e
            Rails.logger.warn("Openrouteservice json response received in unexpected format: #{e}")
            return nil
        end
        
        duration # Return duration in seconds
    rescue RestClient::ExceptionWithResponse => e
        # Handle API errors
        Rails.logger.warn("Error fetching route duration: #{e.response.body}")
        nil
    end
end
