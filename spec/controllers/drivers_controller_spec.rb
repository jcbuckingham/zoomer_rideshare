require 'rails_helper'
require 'devise'

RSpec.describe DriversController, type: :controller do
    let(:valid_attributes) {
        { home_address: '46 11th St, Queens, NY 11101', email: "driver@example.com", password: "test1234"}
    }
    
    let(:valid_driver) {
        Driver.create!(valid_attributes)
    }

    let(:invalid_attributes) {
        { foo: "bar" }
    }

    let(:valid_ride_attributes) {
        { start_address: '10 43rd Ave, Queens, NY 11101', destination_address: '25-03 40th Ave, Queens, NY 11101' }
    }
  
    describe "GET #show" do
        before :each do
            allow_any_instance_of(Warden::Proxy).to receive(:authenticate!).and_return(true)
            request.env['warden'] = double("Warden", authenticate: valid_driver, authenticate!: valid_driver)
        end

        context "with a valid driver" do
            it "returns a success response" do
                sign_in :valid_driver
                
                get :show, params: { id: valid_driver.id }, format: :json
                puts response.inspect
                expect(response).to be_successful
              end
        end

        context "with an invalid driver" do
            it "returns a unauthorized response" do
                other_driver = Driver.create!(home_address: '46 11th St, Queens, NY 11101', email: "other_driver@example.com", password: "test1234")
                sign_in :valid_driver
                get :show, params: { id: other_driver.id }, format: :json
                expect(response).to have_http_status(:unauthorized)
            end
        end
    end
end
