class FetchAddressCoordsWorker
    include Sidekiq::Worker
  
    def perform(obj_class, obj_id)
        client = OpenrouteserviceClient.new

        if obj_class == "Ride"
            ride = Ride.find(obj_id)
            start_coords = client.convert_address_to_coords(ride.start_address)
            destination_coords = client.convert_address_to_coords(ride.destination_address)

            ride.start_coords = start_coords
            ride.destination_coords = destination_coords
            ride.save!
        else
            driver = Driver.find(obj_id)
            driver_coords = client.convert_address_to_coords(driver.home_address)

            driver.coords = driver_coords
            driver.save!
        end
    rescue HTTParty::Error, JSON::ParserError => e
        Rails.logger.error("Backtrace: #{e.backtrace.join("\n")}")
        Rails.logger.error("Error fetching coords from Openrouteservice: #{e.message}")
    rescue => e
        Rails.logger.error("Database error.  Backtrace: #{e.backtrace.join("\n")}")
    end
end
  