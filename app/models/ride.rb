class Ride < ApplicationRecord
    validates :start_address, :destination_address, presence: true
end
