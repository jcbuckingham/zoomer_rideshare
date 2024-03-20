require 'rails_helper'

RSpec.describe RideScoreCalculator do
    describe '#calculate_score' do
        context 'when the ride distance and ride duration are sufficient for extra earnings' do
            let(:calculator) { RideScoreCalculator.new(
                    commute_distance=10, 
                    commute_duration=0.5, 
                    ride_distance=7, 
                    ride_duration=1
                )
            }

            it 'returns the correct score' do
                # Calculation:
                # Ride Earnings: $12 (base) + $1.50 * 2 (miles beyond 5) + $0.70 * 45 (minutes beyond 15) = $46.50
                # Total Duration: 0.5 (commute duration) + 1 (ride duration) = 1.5
                # Score: $46.50 / 1.5 = 31.00 (rounded to 2 decimal places)
                expect(calculator.calculate_score).to eq(31.0)
            end
        end

        context 'when the ride distance and ride duration are insufficient for extra earnings' do
            let(:calculator) { RideScoreCalculator.new(
                    commute_distance=10, 
                    commute_duration=0.5, 
                    ride_distance=5, 
                    ride_duration=0.25
                )
            }
    
            it 'returns the correct score' do
                # Calculation:
                # Ride Earnings: $12 (base)  = $46.50
                # Total Duration: 0.5 (commute duration) + 0.25 (ride duration) = 0.75
                # Score: $12 (base) / 0.75 = 16.00 (rounded to 2 decimal places)
                expect(calculator.calculate_score).to eq(16.0)
            end
        end
    end
end
