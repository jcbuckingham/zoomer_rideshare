class RideScoreCalculator
    def initialize(commute_distance, commute_duration, ride_distance, ride_duration)
        @commute_distance = commute_distance
        @commute_duration = commute_duration
        @ride_distance = ride_distance
        @ride_duration = ride_duration
    end
  
    def calculate_score
        ride_earnings = calculate_earnings
        total_duration = @commute_duration + @ride_duration
        ride_earnings.to_f / total_duration
    end
  
    private
  
    def calculate_earnings
        base_earnings = 12
        miles_beyond_5 = [@ride_distance - 5, 0].max
        additional_earnings = miles_beyond_5 * 1.50
        time_beyond_15_minutes = [@ride_duration - 0.25, 0].max
    
        earnings_from_distance = base_earnings + additional_earnings
        earnings_from_duration = time_beyond_15_minutes * 60 * 0.70
    
        earnings_from_distance + earnings_from_duration
    end
end
