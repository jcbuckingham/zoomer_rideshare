# frozen_string_literal: true

class Drivers::SessionsController < Devise::SessionsController
    include RackSessionsFix
    respond_to :json

    private

    def respond_with(current_driver, _opts = {})
        render json: {
            status: { 
                code: 200, message: 'Logged in successfully.',
                data: { driver: DriverSerializer.new(current_driver).serializable_hash[:data][:attributes] }
            }
        }, status: :ok
    end

    def respond_to_on_destroy
        if request.headers['Authorization'].present?
            jwt_payload = JWT.decode(request.headers['Authorization'].split(' ').last, ENV.fetch('DEVISE_JWT_SECRET_KEY', "asdf").first
            current_driver = Driver.find(jwt_payload['sub'])
        end
        
        if current_driver
            render json: {
                status: 200,
                message: 'Logged out successfully.'
            }, status: :ok
        else
            render json: {
                status: 401,
                message: "Couldn't find an active session."
            }, status: :unauthorized
        end
    end
end
