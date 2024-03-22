require 'rails_helper'
require 'webmock/rspec'

RSpec.describe OpenrouteserviceClient do
    let(:api_key) { 'test_api_key' }
    let(:client) { OpenrouteserviceClient.new }

    before do
        allow(ENV).to receive(:[]).with('OPENROUTESERVICE_API_KEY').and_return(api_key)
        allow(ENV).to receive(:[]).and_call_original

        allow(RestClient).to receive(:post).and_return(
            double(
                RestClient::Response,
                body: '{"durations": [[0, 862.09, 55.35], [256.58, 243.39, 262.86], [243.39, 473.36, 232.38]], "distances": [[0, 10.5, 2.2], [12.3, 5.7, 20.1], [15.9, 25.6, 8.3]]}',
                code: 200 # Assuming you want to return a success response code
            )
        )
    end

    describe '#get_matrix_duration' do
        let(:driver) { Driver.create!(home_address: '8.681495,49.41461') }
        let!(:ride1) { Ride.create!(start_address: '8.6436,49.41401', destination_address: '8.682301,49.420658') }
        let!(:ride2) { Ride.create!(start_address: '8.6936,49.41401', destination_address: '8.692301,49.420658') }

        it 'returns the matrix durations' do
            rides = Ride.order(id: :desc)
            durations = client.get_matrix_duration(driver, rides)
            expect(durations).to eq(
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
                'metrics' => ['duration', 'distance']
            }

            expect(RestClient).to receive(:post).with(
                ENV["OPENROUTESERVICE_MATRIX_ENDPOINT"],
                expected_payload.to_json,
                headers: { 'Content-Type' => 'application/json', 'Authorization' => anything}
            ).and_return(
                double(
                    RestClient::Response,
                    body: '{"durations": [[0, 862.09, 55.35], [256.58, 243.39, 262.86], [243.39, 473.36, 232.38]]}',
                    code: 200 # Assuming you want to return a success response code
                )
            )
            rides = Ride.order(id: :desc)
            client.get_matrix_duration(driver, rides)
        end

        it 'handles RestClient::ExceptionWithResponse' do
            allow(RestClient).to receive(:post).and_raise(RestClient::ExceptionWithResponse.new(nil, 500))

            expect(Rails.logger).to receive(:warn).with(/Error fetching route duration:/)
            
            rides = Ride.order(id: :desc)
            durations = client.get_matrix_duration(driver, rides)
            expect(durations).to be_nil
        end
    end
end

    # let(:start_coords) { '8.681495,49.41461' }
    # let(:end_coords) { '8.687872,49.420318' }

    # describe '#get_route_duration' do
    #     context 'when the API call is successful' do
    #         before do
    #             stub_request(:get, /api.openrouteservice.org/)
    #             .to_return(status: 200, body: File.read('spec/fixtures/route_duration_response.json'))
    #         end

    #         it 'returns the route duration in seconds' do
    #             duration = client.get_route_duration(start_coords, end_coords)
    #             expect(duration).to eq(281.9)
    #         end
    #     end

    #     context 'when the API call fails' do
    #         before do
    #             stub_request(:get, /api.openrouteservice.org/)
    #             .to_return(status: 500)
    #         end

    #         it 'returns nil' do
    #             duration = client.get_route_duration(start_coords, end_coords)
    #             expect(duration).to be_nil
    #         end
    #     end

    #     context 'when the response format is unexpected' do
    #         before do
    #             stub_request(:get, /api.openrouteservice.org/).to_return(status: 200, body: '{}')
    #         end

    #         it 'returns nil and logs a warning for NoMethodError' do
    #             message = "Openrouteservice json response received in unexpected format: undefined method `[]' for nil"
    #             expect(Rails.logger).to receive(:warn).with(message)
    #             duration = client.get_route_duration(start_coords, end_coords)
    #             expect(duration).to be_nil
    #         end
    #     end
    # end