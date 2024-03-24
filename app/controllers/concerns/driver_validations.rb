module DriverValidations
    extend ActiveSupport::Concern

    # Returns a validation hash with key :driver if successful, else :error_json and :status to return correct error response
    def self.find_and_validate(driver_id)
        return { error_json: { error: "Param driver_id is required" }, status: :bad_request } unless driver_id.present?

        driver = Driver.find(driver_id)
        return { error_json: { error: "Driver not found" }, status: :not_found } unless driver
    
        if driver.home_coords.nil?
            return { error_json: { error: "Driver's record is incomplete. Please use another driver_id." }, status: :bad_request }
        end
        
        driver
    end
end
