class Driver < ApplicationRecord
    validates :home_address, presence: true
end
