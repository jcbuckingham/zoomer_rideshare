module DriverValidations
    extend ActiveSupport::Concern

    # Returns a Driver object if successful, else a hash with error info 
    def self.find_and_validate(driver_id)
        return { error_json: { error: "Param driver_id is required" }, status: :bad_request } unless driver_id.present?
        
        begin
            driver = Driver.find(driver_id)
        rescue ActiveRecord::RecordNotFound
            return { error_json: { error: "Driver not found" }, status: :not_found } unless driver
        end

        if driver.home_coords.nil?
            return { error_json: { error: "Driver's record is incomplete. Please use another driver_id." }, status: :bad_request }
        end
        
        driver
    end
end
