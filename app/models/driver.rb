class Driver < ApplicationRecord
    validates :home_address, presence: true

    def fetch_and_save_coords!
        client = OpenrouteserviceClient.new

        home_coords = client.convert_address_to_coords(home_address)

        update!(home_coords: home_coords) if home_coords
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
        raise "Error saving driver coordinates for driver_id=#{id}: #{e.message}"
    end
end
