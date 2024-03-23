require 'rails_helper'
require 'webmock/rspec'

RSpec.describe OpenrouteserviceClient do
    let(:api_key) { 'test_api_key' }
    let(:client) { OpenrouteserviceClient.new }

    before do
        allow(ENV).to receive(:[]).with('OPENROUTESERVICE_API_KEY').and_return(api_key)
        allow(ENV).to receive(:[]).and_call_original

        allow(HTTParty).to receive(:post).and_return(
            double(
                HTTParty::Response,
                body: '{"durations": [[0, 862.09, 55.35], [256.58, 243.39, 262.86], [243.39, 473.36, 232.38]], "distances": [[0, 10.5, 2.2], [12.3, 5.7, 20.1], [15.9, 25.6, 8.3]]}',
                code: 200 # Assuming you want to return a success response code
            )
        )
    end

    describe '#get_matrix_data' do
        let(:driver) { Driver.create!(home_address: '8.681495,49.41461') }
        let!(:ride1) { Ride.create!(start_address: '8.6436,49.41401', destination_address: '8.682301,49.420658') }
        let!(:ride2) { Ride.create!(start_address: '8.6936,49.41401', destination_address: '8.692301,49.420658') }

        it 'returns the matrix data' do
            rides = Ride.order(id: :desc)
            data = client.get_matrix_data(driver, rides)
            expect(data).to eq(
                {
                    "durations" => [[0, 862.09, 55.35], [256.58, 243.39, 262.86], [243.39, 473.36, 232.38]],
                    "distances" => [[0, 10.5, 2.2], [12.3, 5.7, 20.1], [15.9, 25.6, 8.3]]
                }
            )
        end

        it 'makes the correct API call' do
            # expect rides in desc order by id
            expected_payload = {
                'locations' => [
                    [8.681495, 49.41461],  # driver.home_address
                    [8.6936, 49.41401],    # ride2.start_address
                    [8.692301, 49.420658], # ride2.destination_address
                    [8.6436, 49.41401],    # ride1.start_address
                    [8.682301, 49.420658]  # ride1.destination_address
                ],
                'metrics' => ['duration', 'distance'],
                'resolve_locations': false,
                'units': 'mi'
            }
            expect(HTTParty).to receive(:post).with(
                "#{ENV["OPENROUTESERVICE_ENDPOINT"]}/v2/matrix/driving-car",
                body: expected_payload.to_json,
                headers: { 
                    'Content-Type' => 'application/json', 
                    'Authorization' => anything,
                    'Accept' => 'application/json',
                }
            ).and_return(
                double(
                    HTTParty::Response,
                    body: '{"durations": [[0, 862.09, 55.35], [256.58, 243.39, 262.86], [243.39, 473.36, 232.38]]}',
                    code: 200 # Assuming you want to return a success response code
                )
            )
            rides = Ride.order(id: :desc)
            client.get_matrix_data(driver, rides)
        end

        it 'handles HTTParty::Error' do
            allow(HTTParty).to receive(:post).and_raise(HTTParty::Error.new)
            rides = Ride.order(id: :desc)
          
            expect(Rails.logger).to receive(:error).with(/Error fetching route durations and distances/)
            
            expect { client.get_matrix_data(driver, rides) }.to raise_error(HTTParty::Error)
        end
    end

    describe '#convert_address_to_coords' do
        let(:client) { described_class.new }
        let(:address) { '1600 Amphitheatre Parkway, Mountain View, CA' }
        let(:latitude) { 37.4224082 }
        let(:longitude) { -122.0856086 }
        let(:response_body) do
        {
            "features" => [
            {
                "geometry" => {
                "coordinates" => [longitude, latitude]
                }
            }
            ]
        }.to_json
        end

        context 'when the address is valid' do
            before do
                allow(HTTParty).to receive(:get).and_return(double(body: response_body))
            end

            it 'returns the coordinates' do
                expect(client.convert_address_to_coords(address)).to eq("#{latitude},#{longitude}")
            end
        end

        context 'when the address is invalid' do
            before do
                allow(HTTParty).to receive(:get).and_return(double(body: { "features" => [] }.to_json))
            end

            it 'raises an InvalidAddressError' do
                expect { client.convert_address_to_coords(address) }.to raise_error(InvalidAddressError)
            end
        end

        context 'when an HTTP error occurs' do
            before do
                allow(HTTParty).to receive(:get).and_raise(HTTParty::Error, 'HTTP error')
            end

            it 'raises the error' do
                expect { client.convert_address_to_coords(address) }.to raise_error(HTTParty::Error, 'HTTP error')
            end
        end

        context 'when a JSON parsing error occurs' do
            before do
                allow(HTTParty).to receive(:get).and_return(double(body: 'invalid json'))
            end

            it 'raises the error' do
                expect { client.convert_address_to_coords(address) }.to raise_error(JSON::ParserError)
            end
        end
    end
end
