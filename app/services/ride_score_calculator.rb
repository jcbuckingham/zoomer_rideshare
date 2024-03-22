class RideScoreCalculator
    def initialize(driver_rides)
        @driver_rides=driver_rides
    end
  
    def calculate_scores
        @driver_rides.routes_info.each do |ride_data|
            ride_earnings = calculate_earnings(ride_data)
            total_duration = ride_data.commute_duration + ride_data.ride_duration
            ride_data.ride_score = ride_earnings.to_f / total_duration
        end
    end
  
    private
  
    def calculate_earnings(ride)
        base_earnings = 12
        miles_beyond_5 = [ride.ride_distance - 5, 0].max
        additional_earnings = miles_beyond_5 * 1.50
        time_beyond_15_minutes = [ride.ride_duration - 0.25, 0].max
    
        earnings_from_distance = base_earnings + additional_earnings
        earnings_from_duration = time_beyond_15_minutes * 60 * 0.70
    
        earnings_from_distance + earnings_from_duration
    end
end
