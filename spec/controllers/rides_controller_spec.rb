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
                    "Validation failed: Start address can't be blank, Destination address can't be blank, Start address is invalid, Destination address is invalid"
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
        let(:driver) { Driver.create!(home_address: '8.6506,49.41401') }
        let(:ride1) { Ride.create!(start_address: '8.6436,49.41401', destination_address: '8.682301,49.420658') }
        let(:ride2) { Ride.create!(start_address: '8.6936,49.41401', destination_address: '8.692301,49.420658') }

        before do
            allow(Driver).to receive(:find).with(driver.id.to_s).and_return(driver)
            allow(Ride).to receive(:order).with(id: :desc).and_return([ride1, ride2])

            # Stub the method call to fetch ride data
            allow(controller).to receive(:fetch_ride_data).and_return([ride1, ride2])
        end

        it 'returns a list of rides for the driver' do
            get :index, params: { driver_id: driver.id }
            expect(response).to have_http_status(:success)
            expect(JSON.parse(response.body)).to eq([ride1.as_json, ride2.as_json])
        end
    end

    describe "RouteDataConcern" do
        let!(:ride1) { Ride.create!(start_address: '8.6436,49.41401', destination_address: '8.682301,49.420658') }
        let!(:ride2) { Ride.create!(start_address: '8.6936,49.41401', destination_address: '8.692301,49.420658') }

        it "fetches and processes all ride data from Openrouteservice" do
            data = JSON.parse(File.read('spec/fixtures/matrix_duration_response.json'))
            durations = data["durations"]
            distances = data["distances"]
            expected_result = [
                { commute_duration: 862.09, commute_distance: 4.59, ride_duration: 569.45, ride_distance: 2.76 }, 
                { commute_duration: 256.58, commute_distance: 0.88, ride_duration: 192.43, ride_distance: 0.6 }
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
