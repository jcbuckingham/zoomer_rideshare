class Ride < ApplicationRecord
    include RideProcessing

    attr_accessor :score

    validates :start_address, :destination_address, presence: true

    def fetch_and_save_coords!
        client = OpenrouteserviceClient.new

        start_coords = client.convert_address_to_coords(start_address)
        destination_coords = client.convert_address_to_coords(destination_address)
    
        update!(start_coords: start_coords, destination_coords: destination_coords)
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
        raise "Error saving ride coordinates for ride_id=#{id}"
    end
end
