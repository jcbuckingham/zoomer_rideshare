require 'rails_helper'

RSpec.describe RidesController, type: :controller do
    let(:valid_attributes) {
        { start_address: '10 43rd Ave, Queens, NY 11101', destination_address: '25 40th Ave, Queens, NY 11101' }
    }

    let(:invalid_attributes) {
        { foo: "bar" }
    }

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

    describe "GET #show" do
        context "with a valid ride" do
            it "returns a success response" do
                ride = Ride.create!(valid_attributes)
            get :show, params: { id: ride.to_param }, format: :json
            expect(response).to be_successful
            end
        end

        context "with an invalid ride" do
            it "returns a not_found response" do
                get :show, params: { id: 100 }, format: :json
                expect(response).to have_http_status(:not_found)
            end
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
        context "with a valid ride" do
            it "destroys the requested ride" do
                ride = Ride.create!(valid_attributes)
                expect {
                    delete :destroy, params: { id: ride.to_param }, format: :json
                }.to change(Ride, :count).by(-1)
            end
        end

        context "with an invalid ride" do
            it "returns bad_request" do
                delete :destroy, params: { id: 100 }, format: :json
                expect(response).to have_http_status(:bad_request)
            end
        end
    end

    describe 'GET #index' do
        before do
            allow(HTTParty).to receive(:post).and_return(
                double(
                    HTTParty::Response,
                    body: File.read('spec/fixtures/matrix_response.json'),
                    code: 200
                )
            )
        end

        it 'returns a list of rides for the driver sorted by score' do
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
            expected_rides = [ride3.as_json, ride4.as_json]            
            total_rides = Ride.count
          
            get :index, params: { driver_id: driver.id, page: 2, per_page: 2 }
            expect(response).to have_http_status(:success)
            
            expected_response = {
              "page" => 2,
              "per_page" => 2,
              "rides" => expected_rides,
              "total_rides" => total_rides
            }
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

        context "without driver_id param" do
            it 'returns an error' do
                post :index
                expect(response).to have_http_status(:bad_request)
                expect(response.parsed_body["error"]).to eq(
                    "Param driver_id is required"
                )
            end
        end
    end
end
