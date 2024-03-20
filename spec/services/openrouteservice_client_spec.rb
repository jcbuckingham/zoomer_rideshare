require 'rails_helper'
require 'webmock/rspec'

RSpec.describe OpenrouteserviceClient do
    let(:api_key) { 'test_api_key' }
    let(:client) { OpenrouteserviceClient.new(api_key) }
    let(:start_coords) { '8.681495,49.41461' }
    let(:end_coords) { '8.687872,49.420318' }

    describe '#get_route_duration' do
        context 'when the API call is successful' do
            before do
                stub_request(:get, /api.openrouteservice.org/)
                .to_return(status: 200, body: File.read('spec/fixtures/route_duration_response.json'))
            end

            it 'returns the route duration in seconds' do
                duration = client.get_route_duration(start_coords, end_coords)
                expect(duration).to eq(281.9)
            end
        end

        context 'when the API call fails' do
            before do
                stub_request(:get, /api.openrouteservice.org/)
                .to_return(status: 500)
            end

            it 'returns nil' do
                duration = client.get_route_duration(start_coords, end_coords)
                expect(duration).to be_nil
            end
        end

        context 'when the response format is unexpected' do
            before do
                stub_request(:get, /api.openrouteservice.org/).to_return(status: 200, body: '{}')
            end

            it 'returns nil and logs a warning for NoMethodError' do
                message = "Openrouteservice json response received in unexpected format: undefined method `[]' for nil"
                expect(Rails.logger).to receive(:warn).with(message)
                duration = client.get_route_duration(start_coords, end_coords)
                expect(duration).to be_nil
            end
        end
    end
end
