class RidesController < ApplicationController
    include PaginationService

    # GET /rides?driver_id=:driver_id
    def index
        # Driver validation
        validation_result = Driver.find_and_validate(params[:driver_id])
  
        unless validation_result[:error_json].nil?
          render json: validation_result[:error_json], status: validation_result[:status]
          return
        end

        # Paginate the Rides and return the paginated response
        begin
            response = PaginationService.get_paginated_rides_response(validation_result[:driver], params[:page], params[:per_page])
        rescue HTTParty::Error, JSON::ParserError => e
            render json: { error: "Ride information could not be fetched.", status: :service_unavailable }
            return
        rescue => e
            render json: { error: "An unexpected error occurred: #{e.message}", status: :internal_server_error }
            return
        end

        render json: response
    end

    # GET /rides/:id
    def show
        begin
            @ride = Ride.find(params[:id])
        rescue ActiveRecord::RecordNotFound
            render json: { error: "Ride not found" }, status: :not_found
            return
        end
        render json: @ride
    end
  
    # POST /rides
    def create
        begin
            @ride = Ride.create!(ride_params)
        rescue => e
            render json: { error: e.message }, status: :bad_request
            return
        end

        # Enqueue Sidekiq job to fetch ride coords offline
        FetchAddressCoordsWorker.perform_async("Ride", @ride.id)

        render json: @ride, status: :created, location: @ride
    end
  
    # DELETE /rides/:id
    def destroy
        begin
            @ride = Ride.find(params[:id])
        rescue => e
            render json: { error: e.message }, status: :bad_request
            return
        end
        @ride.destroy if @ride
    end
  
    private
    
    # Only allow a list of trusted parameters through.
    def ride_params
        params.require(:ride).permit(:start_address, :destination_address)
    end
end
