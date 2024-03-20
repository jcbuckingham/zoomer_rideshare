class Ride < ApplicationRecord
    GEO_COORDS_REGEX = /-?\d+\.\d+,-?\d+\.\d+/
    validates :start_address, :destination_address, presence: true
    validates :start_address, :destination_address, format: { with: GEO_COORDS_REGEX }
end
