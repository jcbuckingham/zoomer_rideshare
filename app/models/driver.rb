class Driver < ApplicationRecord
    include Devise::JWT::RevocationStrategies::JTIMatcher

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
    devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :jwt_authenticatable, jwt_revocation_strategy: self

    validates :home_address, presence: true

    def fetch_and_save_coords!
        client = OpenrouteserviceClient.new

        home_coords = client.convert_address_to_coords(home_address)

        update!(home_coords: home_coords) if home_coords
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
        raise "Error saving driver coordinates for driver_id=#{id}: #{e.message}"
    end

    def jwt_payload
        puts "jwt_payload"
        puts super.inspect
        super.merge({ scope: 'driver' })
    end
end
