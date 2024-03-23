module RideProcessing
    extend ActiveSupport::Concern
  
    included do
        validates :start_address, :destination_address, presence: true
    end
  
    class_methods do
        def prepare_data(driver)
            rides = Ride.all
    
            rides = fetch_ride_data(driver, rides)
            ride_ids = rides.map(&:id)
    
            cache_key = "rides_for_driver_#{driver.id}"
            Rails.cache.write(cache_key, ride_ids, expires_in: 5.minutes) unless ride_ids.empty?
    
            rides
        end
    
        def fetch_ride_data(driver, rides)
            client = OpenrouteserviceClient.new
            json_data = client.get_matrix_data(driver, rides)
            
            driver_rides = process_matrix_route_data(json_data["durations"], json_data["distances"], rides)
            rsc = RideScoreCalculator.new(driver_rides)
            rsc.calculate_scores
    
            driver_rides.sort_routes_by_score!
            driver_rides.routes_info.map(&:ride)
        end
    
        def process_matrix_route_data(durations, distances, rides)
            driver_rides = DriverRides.new(routes_info=[])
            driver_to_start_coords_durations = durations[0]
            driver_to_start_coords_distances = distances[0]
            ride_index = 0
    
            durations.zip(distances).each_with_index do |ride_data, i|
                next if i.even? || i.zero?
        
                route_info = RideInfo.new(
                    commute_distance: driver_to_start_coords_distances[i],
                    commute_duration: driver_to_start_coords_durations[i],
                    ride_distance: ride_data.last[i + 1],
                    ride_duration: ride_data.first[i + 1],
                    ride: rides[ride_index]
                )
                driver_rides.routes_info << route_info
                ride_index += 1
            end
    
            driver_rides
        end
    end
  
    class DriverRides < Struct.new(:routes_info)
        def sort_routes_by_score!
            routes_info.sort_by! { |route_info| -route_info.ride_score }
        end
    end
  
    class RideInfo < Struct.new(
        :commute_distance, 
        :commute_duration, 
        :ride_distance, 
        :ride_duration,
        :ride,
        :ride_score
    )
    end
end
  