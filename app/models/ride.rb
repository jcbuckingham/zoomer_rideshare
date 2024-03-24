class Ride < ApplicationRecord
    include RideProcessing
    
    attr_accessor :score

    validates :start_address, :destination_address, presence: true
end
