require 'determinator/retrieve/dynaconf'
require 'spec_helper'
require 'webmock/rspec'

RSpec.describe Determinator::Retrieve::Dynaconf do
  describe '#retrieve' do
    subject(:retrieve) { described_class.new(params).retrieve(feature_id) }

    let(:base_url) { 'http://DYNACONF_HOST:4343' }
    let(:service_name) { 'MY-SERVICE' }
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
    let(:expected_url) { "#{base_url}/scopes/florence-#{feature_id}/feature" }

    context 'when client is not injected' do
      let(:params) { { base_url: base_url, service_name: service_name } }

      include_examples 'retrieve tests'
    end

    context 'when client is injected' do
      let(:params) { { base_url: base_url, service_name: service_name, client: client } }

      context 'when the client is a Faraday connection' do
        let(:client) { Faraday.new }

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
