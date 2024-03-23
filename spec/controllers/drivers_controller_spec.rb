require 'rails_helper'

RSpec.describe DriversController, type: :controller do
    let(:valid_attributes) {
        { home_address: '46 11th St, Queens, NY 11101' }
    }

    let(:invalid_attributes) {
        { foo: "bar" }
    }

    let(:valid_ride_attributes) {
        { start_address: '10 43rd Ave, Queens, NY 11101', destination_address: '25-03 40th Ave, Queens, NY 11101' }
    }
  
    describe "GET #show" do
        context "with a valid driver" do
            it "returns a success response" do
                driver = Driver.create!(valid_attributes)
                get :show, params: { id: driver.to_param }, format: :json
                expect(response).to be_successful
            end
        end

        context "with an invalid driver" do
            it "returns a not_found response" do
                get :show, params: { id: 100 }, format: :json
                expect(response).to have_http_status(:not_found)
            end
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
                    "Validation failed: Home address can't be blank"                )
                expect(response.content_type).to eq('application/json; charset=utf-8')
            end
        end
    end

    describe "DELETE #destroy" do
        context "with a valid driver" do
            it "destroys the requested driver" do
                driver = Driver.create!(valid_attributes)
                expect {
                    delete :destroy, params: { id: driver.to_param }, format: :json
                }.to change(Driver, :count).by(-1)
            end
        end

        context "with an invalid driver" do
            it "returns bad_request" do
                delete :destroy, params: { id: 100 }, format: :json
                expect(response).to have_http_status(:bad_request)
            end
        end
    end
end
