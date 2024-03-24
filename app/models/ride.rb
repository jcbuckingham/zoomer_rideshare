class Ride < ApplicationRecord
    include RideProcessing

    attr_accessor :score

    validates :start_address, :destination_address, presence: true

    def fetch_and_save_coords!
        client = OpenrouteserviceClient.new

        start_coords = client.convert_address_to_coords(start_address)
        destination_coords = client.convert_address_to_coords(destination_address)
    
        update!(start_coords: start_coords, destination_coords: destination_coords)
    rescue StandardError => e
        raise "Error saving driver coordinates for driver_id=#{id}: #{e.message}"
    end
end
