class FetchAddressCoordsWorker
    include Sidekiq::Worker
  
    # After a Driver or Ride has been created, this runs asynchronously and fetches
    # coordinates from Openrouteservice based on the objects address(es).
    # While this is faster than waiting on a 3rd party call, one downside to the current
    # implementation is that there is no way to set the coords for a ride if something 
    # goes wrong. Handling this is outside the scope of work, so I'll leave it for now.
    def perform(obj_class, obj_id)
        client = OpenrouteserviceClient.new

        if obj_class == "Ride"
            ride = Ride.find(obj_id.to_i)
            start_coords = client.convert_address_to_coords(ride.start_address)
            destination_coords = client.convert_address_to_coords(ride.destination_address)

            ride.start_coords = start_coords
            ride.destination_coords = destination_coords
            ride.save!
        else
            driver = Driver.find(obj_id.to_i)
            driver_home_coords = client.convert_address_to_coords(driver.home_address)

            driver.home_coords = driver_home_coords
            driver.save!
        end
    rescue HTTParty::Error, JSON::ParserError => e
        Rails.logger.error("Error fetching coords from Openrouteservice: #{e.message}; Backtrace: #{e.backtrace.join("\n")}")
    rescue => e
        ap e
        Rails.logger.error("Database error. Backtrace: #{e.backtrace.join("\n")}")
    end
end
  