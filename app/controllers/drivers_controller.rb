class DriversController < ApplicationController
    before_action :authenticate_driver!
    before_action :authorize_driver

    # GET /drivers/:id
    def show
        begin
            @driver = Driver.find(params[:id])
        rescue ActiveRecord::RecordNotFound
            render json: { error: "Driver not found" }, status: :not_found
            return
        end
        render json: @driver
    end

    private
    
    # Only allow a list of trusted parameters through.
    def driver_params
        params.require(:driver).permit(:home_address)
    end

    def authorize_driver
        @driver = Driver.find(params[:id])

        unless current_driver.id == @driver.id
          render json: { error: "Unauthorized" }, status: :unauthorized
        end
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Driver not found" }, status: :not_found
      end
end
