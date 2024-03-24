class Driver < ApplicationRecord
    validates :home_address, presence: true

    # Returns a validation hash with key :driver if successful, else :error_json and :status to return correct error response
    def self.find_and_validate(driver_id)
        return { error_json: { error: "Param driver_id is required" }, status: :bad_request } unless driver_id.present?

        driver = find_by(id: driver_id)
        return { error_json: { error: "Driver not found" }, status: :not_found } unless driver
    
        if driver.home_coords.nil?
          return { error_json: { error: "Driver's record is incomplete. Please use another driver_id." }, status: :bad_request }
        end
        
        { driver: driver }
    end

    def fetch_and_save_coords!
        client = OpenrouteserviceClient.new

        home_coords = client.convert_address_to_coords(home_address)

        update!(home_coords: home_coords)
    rescue StandardError => e
        raise "Error saving driver coordinates for driver_id=#{id}: #{e.message}"
    end
end
