require 'rails_helper'
# require_relative '../../app/controllers/concerns/route_data_concern.rb'

RSpec.describe RidesController, type: :controller do
    controller RidesController do
        include RouteDataConcern
    end

    let(:valid_attributes) {
        { start_address: '8.681495,49.41461', destination_address: '8.687872,49.420318' }
    }

    let(:invalid_attributes) {
        { foo: "bar" }
    }

    let(:driver) { Driver.create!(home_address: '8.681495,49.41461') }
    let!(:ride1) { Ride.create!(start_address: '8.6825,49.41401', destination_address: '8.682311,49.414658') }
    let!(:ride2) { Ride.create!(start_address: '8.6815,49.41401', destination_address: '8.692321,49.41461') }
    let!(:ride3) { Ride.create!(start_address: '8.6816,49.41401', destination_address: '8.682301,49.414658') }
    let!(:ride4) { Ride.create!(start_address: '8.68171,49.41401', destination_address: '8.692301,49.414658') }

    describe "GET #show" do
        it "returns a success response" do
            ride = Ride.create!(valid_attributes)
            get :show, params: { id: ride.to_param }, format: :json
            expect(response).to be_successful
        end
    end

    describe "POST #create" do
        context "with valid params" do
            it "creates a new Ride" do
                expect {
                    post :create, params: { ride: valid_attributes }, format: :json
                }.to change(Ride, :count).by(1)
            end

            it "renders a JSON response with the new ride" do
                post :create, params: { ride: valid_attributes }, format: :json
                expect(response).to have_http_status(:created)
                expect(response.content_type).to eq('application/json; charset=utf-8')
            end
        end

        context "with invalid params" do
            it "renders a JSON response with errors for the new ride" do
                post :create, params: { ride: invalid_attributes }, format: :json
                expect(response).to have_http_status(:bad_request)
                expect(response.parsed_body["error"]).to eq(
                    "Validation failed: Start address can't be blank, Destination address can't be blank"
                )
                expect(response.content_type).to eq('application/json; charset=utf-8')
            end
        end
    end

    describe "DELETE #destroy" do
        it "destroys the requested ride" do
            ride = Ride.create!(valid_attributes)
            expect {
                delete :destroy, params: { id: ride.to_param }, format: :json
            }.to change(Ride, :count).by(-1)
        end
    end

    describe 'GET #index' do
        before do
            # Stub the method call to fetch ride data
            # allow(controller).to receive(:fetch_ride_data).and_return([ride1, ride2, ride3, ride4])
            allow(HTTParty).to receive(:post).and_return(
                double(
                    HTTParty::Response,
                    body: File.read('spec/fixtures/matrix_duration_response.json'),
                    code: 200 # Assuming you want to return a success response code
                )
            )
        end

        it 'returns a list of rides for the driver sorted by score' do
            driver_rides = 
            get :index, params: { driver_id: driver.id }
            expect(response).to have_http_status(:success)
            expected_response = {
                "page" => 1,
                "per_page" => 10,
                "rides" => [ride2.as_json, ride1.as_json, ride3.as_json, ride4.as_json],
                "total_rides" => 4
            }

            expect(JSON.parse(response.body)).to eq(expected_response)
        end

        it 'is paginated' do
            # Define different page and per_page values
            page = 2
            per_page = 2
            
            # Calculate the expected rides for the specified page and per_page
            expected_rides = [ride3.as_json, ride4.as_json]
            
            # Calculate the total number of rides (for total_rides field)
            total_rides = Ride.count
          
            # Call the index action with the specified page and per_page values
            get :index, params: { driver_id: driver.id, page: page, per_page: per_page }
            
            # Check if the response is successful
            expect(response).to have_http_status(:success)
            
            # Construct the expected response hash
            expected_response = {
              "page" => page,
              "per_page" => per_page,
              "rides" => expected_rides,
              "total_rides" => total_rides
            }
          
            # Check if the response body matches the expected response
            expect(JSON.parse(response.body)).to eq(expected_response)
        end

        context "with cached driver data" do
            let(:cached_ride_ids) { Ride.order(id: :desc).pluck(:id) }

            before do
                allow(Rails.cache).to receive(:read).with("rides_for_driver_#{driver.id}").and_return(cached_ride_ids)
            end

            it 'returns cached rides' do
                get :index, params: { driver_id: driver.id, page: 1, per_page: 3 }
                expect(response).to have_http_status(:success)
                expect(JSON.parse(response.body)['rides'].count).to eq(3)
                expect(JSON.parse(response.body)['rides']).to eq([ride4.as_json, ride3.as_json, ride2.as_json])
                expect(Rails.cache).to have_received(:read).with("rides_for_driver_#{driver.id}")
            end
        end
    end

    describe "RouteDataConcern" do
        it "fetches and processes all ride data from Openrouteservice" do
            data = JSON.parse(File.read('spec/fixtures/matrix_duration_response.json'))
            durations = data["durations"]
            distances = data["distances"]
            expected_result = [
                { commute_duration: 14.97, commute_distance: 0.04, ride_duration: 94.3, ride_distance: 0.24 }, 
                { commute_duration: 14.45, commute_distance: 0.04, ride_duration: 228.56, ride_distance: 0.77 },
                { commute_duration: 56.94, commute_distance: 0.15, ride_duration: 108.56, ride_distance: 0.28 }, 
                { commute_duration: 1.6, commute_distance: 0.0, ride_duration: 2.38, ride_distance: 0.01 }
            ]
            result = subject.process_matrix_route_data(durations, distances, Ride.order(id: :desc))
            expect(result.class).to be(RouteDataConcern::DriverRides)

            result.routes_info.zip(expected_result).each do |res, exp|
                expect(res.commute_duration).to eq(exp[:commute_duration])
                expect(res.commute_distance).to eq(exp[:commute_distance])
                expect(res.ride_duration).to eq(exp[:ride_duration])
                expect(res.ride_distance).to eq(exp[:ride_distance])
                expect(res.ride.class).to eq(Ride)
            end
        end
    end
end
