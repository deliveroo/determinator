require 'determinator/retrieve/http_retriever'
require 'spec_helper'
require 'webmock/rspec'

RSpec.describe Determinator::Retrieve::HttpRetriever do
  describe '#retrieve' do
    subject(:retrieve) { described_class.new(params).retrieve(feature_id) }
    let(:client){
      Faraday.new(base_url)
    }
    let(:base_url) { 'http://actortracking.dev' }
    let(:service_name) { 'MY-SERVICE' }
    let(:feature_id) { 'some-feature' }
    let(:feature_json) { {
      name: "Feature one",
      identifier: "feature",
      bucket_type: "id",
      structured_bucket: "request.customer.guid",
      target_groups: [{
        rollout: 65536,
        constraints: {}
      }],
      active: true,
      overrides: {}
    } }
    let(:expected_url) { "#{base_url}/features/#{feature_id}" }

    context 'when client is injected' do
      let(:params) { { connection: client } }

      context 'when the client is a Faraday connection' do
        include_examples 'retrieve tests'
      end

      context 'when the client is not a Faraday connection' do
        let(:client) { 'CLIENT' }

        it 'raises an ArgumentError' do
          expect { retrieve }.to raise_error(ArgumentError)
        end
      end
    end
  end
end
