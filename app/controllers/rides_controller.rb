class RidesController < ApplicationController
    before_action :authenticate_driver!
    include PaginationService

    # GET /rides?driver_id=:driver_id
    def index
        # Driver validation hash: { error_json: :error_json, status: :status } or valid Driver object
        validation_result = DriverValidations.find_and_validate(params[:driver_id])
  
        if validation_result.is_a?(Hash)
            render json: validation_result[:error_json], status: validation_result[:status]
            return
        end

        # Paginate the Rides and return the paginated response
        begin
            response = PaginationService.get_paginated_rides_response(validation_result, params[:page], params[:per_page])
        rescue HTTParty::Error, JSON::ParserError => e
            render json: { error: "Ride information could not be fetched." }, status: :service_unavailable
            return
        rescue => e
            render json: { error: "An unexpected error occurred: #{e.message}" }, status: :internal_server_error
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

        begin
            @ride.fetch_and_save_coords!
        rescue InvalidAddressError
            render json: { error: "Address is invalid." }, status: :bad_request
            return
        rescue HTTParty::Error, JSON::ParserError => e
            render json: { error: "Address conversion error." }, status: :service_unavailable
            return
        end

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
