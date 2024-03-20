class Driver < ApplicationRecord
    # TODO: move this centrally
    GEO_COORDS_REGEX = /-?\d+\.\d+,-?\d+\.\d+/
    validates :home_address, presence: true
    validates :home_address, format: { with: GEO_COORDS_REGEX }
end
