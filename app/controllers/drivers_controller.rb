class DriversController < ApplicationController
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

    # POST /drivers
    def create
        begin
            @driver = Driver.create!(driver_params)

            # Enqueue Sidekiq job to fetch ride coords
            FetchAddressCoordsWorker.perform_async("Driver", @driver.id)

            render json: @driver, status: :created, location: @driver
        rescue => e
            render json: { error: e.message }, status: :bad_request
        end
    end

    # DELETE /drivers/:id
    def destroy
        begin
            @driver = Driver.find(params[:id])
        rescue => e
            render json: { error: e.message }, status: :bad_request
            return
        end
        @driver.destroy if @driver
    end

    private
    
    # Only allow a list of trusted parameters through.
    def driver_params
        params.require(:driver).permit(:home_address)
    end
end
