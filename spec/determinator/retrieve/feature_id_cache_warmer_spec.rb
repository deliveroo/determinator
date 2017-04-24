require 'spec_helper'

describe Determinator::Retrieve::FeatureIdCacheWarmer do
  let(:client) { double('client') }
  let(:redis) { double('redis') }

  describe '#call' do
    let(:feature_id) { 1 }
    let(:feature_name) { "Experiment X" }
    let(:cache_key) { "determinator_index:#{feature_name}" }
    let(:url) { "https://actor-tracking.dev/features/#{feature_id}" }
    let(:payload) { { 'url' => url } }
    let(:body) { { 'id' => feature_id, 'name' => feature_name, 'bucket_type' => 'guid' } }
    let(:response) { OpenStruct.new(body: body) }

    before do
      allow(client).to receive(:get).with(url).and_return(response)
      allow(::Routemaster::APIClient).to receive(:new).and_return(client)
      allow(::Routemaster::Config).to receive(:cache_redis).and_return(redis)
    end

    subject { described_class.new(payload) }

    it 'should fetch the feature and set cache key' do
      expect(client).to receive(:get)
      expect(redis).to receive(:set).with(cache_key, feature_id)
      subject.call
    end

    context 'with invalid response' do
      let(:body) { { 'id' => feature_id, 'name' => feature_name, 'not_real_feature' => 'guid' } }

      it 'should not set cache key' do
        expect(redis).to_not receive(:set).with(cache_key, feature_id)
        subject.call
      end
    end
  end
end
