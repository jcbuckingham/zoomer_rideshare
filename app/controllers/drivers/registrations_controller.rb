# frozen_string_literal: true

class Drivers::RegistrationsController < Devise::RegistrationsController
    include RackSessionsFix
    respond_to :json

    private

    def respond_with(current_driver, _opts = {})
        if resource.persisted?
            begin
                @driver.fetch_and_save_coords!
            rescue InvalidAddressError
                render json: { error: "Address is invalid." }, status: :bad_request
                return
            rescue HTTParty::Error, JSON::ParserError => e
                render json: { error: "Address conversion error." }, status: :service_unavailable
                return
            end
            
            render json: {
                status: {code: 200, message: 'Signed up successfully.'},
                data: DriverSerializer.new(current_driver).serializable_hash[:data][:attributes]
            }
        else
            render json: {
                status: {message: "Driver couldn't be created successfully. #{current_driver.errors.full_messages.to_sentence}"}
            }, status: :unprocessable_entity
        end
    end

  def sign_up_params
    params.require(:driver).permit(:email, :password, :home_address, :name)
  end
end
