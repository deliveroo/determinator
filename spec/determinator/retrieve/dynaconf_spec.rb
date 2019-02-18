require 'determinator/retrieve/dynaconf'
require 'spec_helper'
require 'webmock/rspec'

RSpec.describe Determinator::Retrieve::Dynaconf do
  describe '#retrieve' do
    let(:base_url) { 'http://DYNACONF_HOST:4343' }
    let(:feature_id) { 'some-feature' }
    let(:feature_json) { {
      name: "Feature one",
      identifier: "feature",
      bucket_type: "id",
      target_groups: [{
        rollout: 65536,
        constraints: {}
      }],
      active: true,
      overrides: {}
    } }
    let(:client) { Faraday.new }
    let(:expected_url) { "#{base_url}/scopes/florence-#{feature_id}/feature" }

    shared_examples 'retrieve tests' do
      before do
        allow(Determinator).to receive(:notice_error)
        stub_request(:get, expected_url).to_return(status: response_status, body: feature_json.to_json)
      end

      context 'when the feature is found' do
        let(:response_status) { 200 }

        context 'when there is no other error' do
          it 'returns a Feature object' do
            expect(retrieve).to be_a(Determinator::Feature)
          end

          it 'sets the properties on the object' do
            expect(retrieve.name).to eql(feature_json[:name])
          end
        end

        context 'when an error occurs' do
          let(:error) { StandardError.new }

          before do
            allow(Determinator::Serializers::JSON).to receive(:load).and_raise(error)
            retrieve
          end

          it 'logs the error' do
            expect(Determinator).to have_received(:notice_error).with(error)
          end

          it { is_expected.to be nil }
        end
      end

      context 'when the feature is not found' do
        let(:response_status) { 404 }

        before do
          retrieve
        end

        it { is_expected.to be nil }
      end
    end

    context 'when client is not injected' do
      subject(:retrieve) { described_class.new(base_url: base_url).retrieve(feature_id) }

      include_examples 'retrieve tests'
    end

    context 'when client is injected' do
      subject(:retrieve) { described_class.new(base_url: base_url, client: client).retrieve(feature_id) }

      include_examples 'retrieve tests'
    end
  end
end
