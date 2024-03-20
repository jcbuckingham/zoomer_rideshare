require 'rails_helper'

RSpec.describe RidesController, type: :controller do
    let(:valid_attributes) {
        { start_address: '8.681495,49.41461', destination_address: '8.687872,49.420318' }
    }

    let(:invalid_attributes) {
        { foo: "bar" }
    }

    describe "GET #index" do
        it "returns a success response" do
            Ride.create!(valid_attributes)
            get :index, format: :json
            expect(response).to be_successful
        end
    end

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
                print({ ride: valid_attributes }.to_json)
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
end
