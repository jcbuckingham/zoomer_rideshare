class DriversController < ApplicationController
    
    # GET /drivers
    def index
        @drivers = Driver.all
        render json: @drivers
    end

    # GET /drivers/:id
    def show
        @driver = Driver.find(params[:id])
        render json: @driver
    end

    # POST /drivers
    def create
        begin
            @driver = Driver.create!(driver_params)
            render json: @driver, status: :created, location: @driver
        rescue => e
            render json: { error: e.message }, status: :bad_request
        end
    end

    # DELETE /drivers/:id
    def destroy
        @driver = Driver.find(params[:id])
        @driver.destroy if @driver
    end

    private
    
    # Only allow a list of trusted parameters through.
    def driver_params
        params.require(:driver).permit(:home_address)
    end
end
