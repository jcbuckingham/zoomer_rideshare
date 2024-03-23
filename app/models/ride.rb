class Ride < ApplicationRecord
    include RideProcessing

    validates :start_address, :destination_address, presence: true
end
