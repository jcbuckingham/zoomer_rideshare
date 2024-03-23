require 'rails_helper'

RSpec.describe Ride, type: :model do
    let(:driver) { Driver.create!(home_address: '46 11th St, Queens, NY 11101', home_coords: '8.681495,49.41461') }
    let!(:ride1) do 
        Ride.create!(
            start_address: '10 43rd Ave, Queens, NY 11101', 
            destination_address: '25 40th Ave, Queens, NY 11101',
            start_coords: '8.6825,49.41401', 
            destination_coords: '8.682311,49.414658'
        )
    end
    let!(:ride2) do 
        Ride.create!(
            start_address: '30 23rd St, Queens, NY 11101', 
            destination_address: '4236 Crescent St, Queens, NY 11101',
            start_coords: '8.6815,49.41401', 
            destination_coords: '8.692321,49.41461'
        )
    end
    let!(:ride3) do
        Ride.create!(
            start_address: '965 1st Ave., New York, NY 10022', 
            destination_address: '36-01 35th Ave, Queens, NY 11106',
            start_coords: '8.6816,49.41401', 
            destination_coords: '8.682301,49.414658'
        )
    end
    let!(:ride4) do
        Ride.create!(
            start_address: '965 1st Ave., New York, NY 10022', 
            destination_address: '10 41st Ave, Queens, NY 11101',
            start_coords: '8.68171,49.41401', 
            destination_coords: '8.692301,49.414658'
        )
    end

    describe "process_matrix_route_data" do
        it "fetches and processes all ride data from Openrouteservice" do
            data = JSON.parse(File.read('spec/fixtures/matrix_response.json'))
            durations = data["durations"]
            distances = data["distances"]
            expected_result = [
                { commute_duration: 14.97, commute_distance: 0.04, ride_duration: 94.3, ride_distance: 0.24 }, 
                { commute_duration: 14.45, commute_distance: 0.04, ride_duration: 228.56, ride_distance: 0.77 },
                { commute_duration: 56.94, commute_distance: 0.15, ride_duration: 108.56, ride_distance: 0.28 }, 
                { commute_duration: 1.6, commute_distance: 0.0, ride_duration: 2.38, ride_distance: 0.01 }
            ]
            result = Ride.process_matrix_route_data(durations, distances, Ride.order(id: :desc))
            expect(result.class).to be(Ride::DriverRides)

            result.rides_info.zip(expected_result).each do |res, exp|
                expect(res.commute_duration).to eq(exp[:commute_duration])
                expect(res.commute_distance).to eq(exp[:commute_distance])
                expect(res.ride_duration).to eq(exp[:ride_duration])
                expect(res.ride_distance).to eq(exp[:ride_distance])
                expect(res.ride.class).to eq(Ride)
            end
        end
    end

    describe "fetch_ride_data" do
        it "fetches all ride data from Openrouteservice and calculates scores" do
            allow_any_instance_of(OpenrouteserviceClient).to receive(:get_matrix_data).and_return({
                "durations" => [ 
                    [0, 14.97, 14.45, 56.94, 1.6], 
                    [94.3, 0, 228.56, 108.56, 2.38], 
                    [13.9, 14.2, 0, 54.74, 2], 
                    [96.22, 0.51, 93.79, 0.0, 228.56], 
                    [242.91, 217.32, 289.5, 217.84, 0.0] 
                ],
                "distances" => [ 
                    [0, 0.04, 0.04, 0.15, 0], 
                    [0.24, 0, 0.77, 0.28, 0.01],
                    [0.1, 0.3, 0, 0.2, 0.1],
                    [0.4, 0.5, 0.77, 0, 0.2],
                    [1.4, 0.4, 0.34, 0.2, 0]
                ]
            })
            driver_rides = Ride.fetch_ride_data(driver, Ride.all)

            expect(driver_rides.rides_info.first.ride).to eq(ride1)
            expect(driver_rides.rides_info.last.ride).to eq(ride2)
            expect(driver_rides.rides_info.size).to eq(2)
        end
    end
end