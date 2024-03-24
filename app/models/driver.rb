class Driver < ApplicationRecord
    validates :home_address, presence: true

    # Returns a validation hash with key :driver if successful, else :error_json and :status to return correct error response
    def self.find_and_validate(driver_id)
        unless driver_id
            return { error_json: { error: "Param driver_id is required" }, status: :bad_request }
        end
        
        begin
            driver = find(driver_id)
        rescue ActiveRecord::RecordNotFound
            return { error_json: { error: "Driver not found" }, status: :not_found }
        end
        
        if driver.home_coords.nil?
            return { error_json: { error: "Driver's record is incomplete. Please use another driver_id." }, status: :bad_request }
        end
        
        { driver: driver }
    end
end
