require 'rails_helper'

RSpec.describe RideScoreCalculator do
    describe '#calculate_score' do
        let(:ride1) { Ride.create!(start_address: '10 43rd Ave, Queens, NY 11101', destination_address: '25-03 40th Ave, Queens, NY 11101') }
        let(:ride2) { Ride.create!(start_address: '965 1st Ave., New York, NY 10022', destination_address: '10 41st Ave, Queens, NY 11101') }
        let(:ride3) { Ride.create!(start_address: '890 8th Ave., New York, NY 10144', destination_address: '10 41st Ave, Queens, NY 11101') }

        let(:ride_info1) do
            Ride::RideInfo.new(
                commute_distance: 10,
                commute_duration: 0.5,
                ride_distance: 7,
                ride_duration: 1,
                ride: ride1
            )
        end
        let(:ride_info2) do
            Ride::RideInfo.new(
                commute_distance: 12.5,
                commute_duration: 1,
                ride_distance: 5,
                ride_duration: 0.25, # 15 minutes
                ride: ride2
            )
        end
        let(:ride_info3) do
            Ride::RideInfo.new(
                commute_distance: 12.5,
                commute_duration: 0.95, # 57 minutes
                ride_distance: 1,
                ride_duration: 0.05,    # 3 minutes
                ride: ride3
            )
        end
        let(:driver_rides) { Ride::DriverRides.new(rides_info:[ride_info1, ride_info2, ride_info3]) }
        let(:calculator) { RideScoreCalculator.new(driver_rides) }

        it 'returns the correct scores for each ride' do
            calculator.calculate_scores

            # Calculation:
            # Ride Earnings: $12 (base) + $1.50 * 2 (miles beyond 5) + $0.70 * 45 (minutes beyond 15) = $46.50
            # Total Duration: 0.5 (commute duration) + 1 (ride duration) = 1.5
            # Score: $46.50 / 1.5 = 31.0
            expect(driver_rides.rides_info.first.ride_score).to eq(31.0)
            # Calculation:
            # Ride Earnings: $12 (base) + $0 (miles beyond 5) + $0 (minutes beyond 15) = $46.50
            # Total Duration: 1 (commute duration) + 0.25 (ride duration) = 1.25
            # Score: $12 / 1.25 = 9.6 
            expect(driver_rides.rides_info.second.ride_score).to eq(9.6)
            # Calculation:
            # Ride Earnings: $12 (base) + $0 (miles beyond 5) + $0 (minutes beyond 15) = $46.50
            # Total Duration: 0.95 (commute duration) + 0.05 (ride duration) = 1
            # Score: $12 / 1 = 12 
            expect(driver_rides.rides_info.last.ride_score).to eq(12)
        end
    end
end
