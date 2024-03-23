require 'rails_helper'

RSpec.describe FetchAddressCoordsWorker, type: :worker do
    describe '#perform' do
        let(:client) { instance_double('OpenrouteserviceClient') }

        context 'when given Ride object' do
            let!(:ride) do 
                Ride.create!(
                    start_address: '10 43rd Ave, Queens, NY 11101', 
                    destination_address: '25 40th Ave, Queens, NY 11101'
                )
            end

            before do
                allow(OpenrouteserviceClient).to receive(:new).and_return(client)
                allow(client).to receive(:convert_address_to_coords).and_return("12.345,67.890")
            end

            it 'updates start and destination coordinates for the ride' do
                described_class.new.perform('Ride', ride.id)
                
                ride.reload
                expect(ride.start_coords).to eq("12.345,67.890")
                expect(ride.destination_coords).to eq("12.345,67.890")
            end
        end

        context 'when given Driver object' do
            let(:driver) { Driver.create!(home_address: '46 11th St, Queens, NY 11101') }

            before do
                allow(OpenrouteserviceClient).to receive(:new).and_return(client)
                allow(client).to receive(:convert_address_to_coords).and_return("12.345,67.890")
            end

            it 'updates home coordinates for the driver' do
                described_class.new.perform('Driver', driver.id)
                
                driver.reload
                expect(driver.home_coords).to eq("12.345,67.890")
            end
        end

        context 'when error occurs during fetching coordinates' do
            let!(:ride) do 
                Ride.create!(
                    start_address: '10 43rd Ave, Queens, NY 11101', 
                    destination_address: '25 40th Ave, Queens, NY 11101'
                )
            end

            before do
                allow(OpenrouteserviceClient).to receive(:new).and_return(client)
            end

            it 'logs error message when HTTParty::Error or JSON::ParserError occurs' do
                allow(client).to receive(:convert_address_to_coords).and_raise(HTTParty::Error)
                expect(Rails.logger).to receive(:error).with(/Error fetching coords from Openrouteservice/)
                
                described_class.new.perform('Ride', ride.id)
            end

            it 'logs error message when other errors occur' do
                allow(client).to receive(:convert_address_to_coords).and_raise(StandardError)
                expect(Rails.logger).to receive(:error).with(/Database error. Backtrace:/)
                
                described_class.new.perform('Ride', ride.id)
            end
        end
    end
end
