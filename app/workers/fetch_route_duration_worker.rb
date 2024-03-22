class FetchRouteDurationWorker
    include Sidekiq::Worker
  
    def perform(ride_id)
        ride = Ride.find(ride_id)
        openrouteservice_client = OpenrouteserviceClient.new(ENV['OPENROUTESERVICE_API_KEY'])
        ride_duration = openrouteservice_client.get_route_duration(ride.start_address, ride.destination_address)
        # Process fetched ride data as needed
        Rails.logger.info("Data received back from openrouteservice: duration is #{ride_duration}")
        Rails.cache.write("ride:#{ride.id}", ride_duration)
        cached_val = Rails.cache.read("ride:#{ride.id}")
        Rails.logger.info("ride:#{ride.id}: #{cached_val}")
    rescue => e
        Rails.logger.error("Error fetching ride data: #{e.message}")
    end
end
  