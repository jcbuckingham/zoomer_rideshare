require 'rails_helper'

RSpec.describe DriversController, type: :controller do
    # TODO: factorybot
    let(:valid_attributes) {
        { home_address: '8.681301,49.43461' }
    }

    let(:invalid_attributes) {
        { foo: "bar" }
    }

    let(:valid_ride_attributes) {
        { start_address: '8.681495,49.41461', destination_address: '8.687872,49.420318' }
    }

    describe "GET #index" do
        it "returns a success response" do
            Driver.create!(valid_attributes)
            get :index, format: :json
            expect(response).to be_successful
        end
    end

    describe "GET drivers/:driver_id/rides#index" do
        let(:driver) { Driver.create!(valid_attributes) } # Assuming you have FactoryBot set up for Driver model
        let!(:rides) { Ride.create!(valid_ride_attributes) } # Assuming you have FactoryBot set up for Ride model
    
        it "returns a success response" do
            get :index, params: { driver_id: driver.id }, format: :json
            expect(response).to be_successful
        end
    
        it "returns all rides for the driver" do
            get :index, params: { driver_id: driver.id }, format: :json
            expect(response.parsed_body.size).to eq(1)
        end
    
        it "returns rides in JSON format" do
            get :index, params: { driver_id: driver.id }, format: :json
            expect(response.content_type).to eq("application/json; charset=utf-8")
        end
    end
  

    describe "GET #show" do
        it "returns a success response" do
            driver = Driver.create!(valid_attributes)
            get :show, params: { id: driver.to_param }, format: :json
            expect(response).to be_successful
        end
    end

    describe "POST #create" do
        context "with valid params" do
            it "creates a new Driver" do
                expect {
                    post :create, params: { driver: valid_attributes }, format: :json
                }.to change(Driver, :count).by(1)
            end

            it "renders a JSON response with the new driver" do
                post :create, params: { driver: valid_attributes }, format: :json
                expect(response).to have_http_status(:created)
                expect(response.content_type).to eq('application/json; charset=utf-8')
            end
        end

        context "with invalid params" do
            it "renders a JSON response with errors for the new driver" do
                post :create, params: { driver: invalid_attributes }, format: :json
                expect(response).to have_http_status(:bad_request)
                expect(response.parsed_body["error"]).to eq(
                    "Validation failed: Home address can't be blank, Home address is invalid"
                )
                expect(response.content_type).to eq('application/json; charset=utf-8')
            end
        end
    end

    describe "DELETE #destroy" do
        it "destroys the requested driver" do
            driver = Driver.create!(valid_attributes)
            expect {
                delete :destroy, params: { id: driver.to_param }, format: :json
            }.to change(Driver, :count).by(-1)
        end
    end
end
