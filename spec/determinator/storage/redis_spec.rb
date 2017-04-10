require 'spec_helper'
require 'determinator/storage/redis'

describe Determinator::Storage::Redis do
  let(:instance) { described_class.new(redis) }
  let(:redis) { double }

  describe '#get_all' do
    subject(:method_call) { instance.get_all }
    let(:features) { 4.times.map { FactoryGirl.create(:feature) } }
    let(:serialized_features) {
      Hash[features.map { |feature|
        [
          "determinator:features:#{feature.name}",
          instance.send(:serialize, feature)
        ]
      }]
    }

    before do
      allow(redis).to receive(:mget) { |keys| serialized_features.values_at(*keys) }
    end

    context 'when only one redis scan is required' do
      before do
        # When Redis.scan has finished a loop it returns "0" as the cursor
        allow(redis).to receive(:scan).with(
          "0", match: 'determinator:features:*'
        ).and_return(["0", serialized_features.keys])
      end

      it { should eq features }
    end

    context 'when multiple scans are required' do
      before do
        expect(redis).to receive(:scan).with(
          # When Redis.scan has more results to return it returns a non-zero cursor
          "0", match: 'determinator:features:*'
        ).and_return(
          ["1", serialized_features.keys[0..1]]
        )

        expect(redis).to receive(:scan).with(
          # The client should send the cursor returned from the previous call
          "1", match: 'determinator:features:*'
        ).and_return(
          # When Redis.scan has finished a loop it returns "0" as the cursor
          ["0", serialized_features.keys[2..3]]
        )
      end

      it "should scan until the cursor loops" do
        # Expectations are before block
        method_call
      end

      it { should eq features }
    end
  end

  describe '#get' do
    subject(:method_call) { instance.get(requested_feature) }
    let(:feature) { FactoryGirl.create(:feature) }
    let(:feature_name) { feature.name }

    before do
      allow(redis).to receive(:get).with(
        "determinator:features:#{requested_feature}"
      ).and_return(
        redis_response
      )
    end

    context 'when a stored feature is requested' do
      let(:requested_feature) { feature_name }
      let(:redis_response) { instance.send(:serialize, feature) }

      it { should eq feature }
    end

    context 'when an unknown feature is requested' do
      let(:requested_feature) { 'somethingelse' }
      let(:redis_response) { nil }

      it { should eq nil }
    end
  end

  describe '#put' do
    subject(:method_call) { instance.put(feature, origin_last_modified) }
    let(:feature) { FactoryGirl.create(:feature) }
    let(:origin_last_modified) { Time.now }

    context 'when the most recent feature seen timestamp is in the future' do
      before do
        instance.instance_variable_set('@origin_last_modified', Time.now + 60)
      end

      it 'should store a serialized copy of the feature in redis' do
        expect(redis).to receive(:set) do |key, data|
          expect(key).to eq "determinator:features:#{feature.name}"
          expect(instance.send(:deserialize, data)).to eq feature
        end
        method_call
      end
    end

    context 'when the most recent feature seen timestamp is in the past' do
      before do
        instance.instance_variable_set('@origin_last_modified', Time.at(0))
      end

      it 'should store a serialized copy of the feature in redis' do
        expect(redis).to receive(:set) do |key, data|
          expect(key).to eq "determinator:features:#{feature.name}"
          expect(instance.send(:deserialize, data)).to eq feature
        end
        expect(redis).to receive(:set) do |key, data|
          expect(key).to eq "determinator:most_recent_feature_seen"
          expect(data).to eq origin_last_modified.to_f
        end
        method_call
        expect(instance.instance_variable_get('@origin_last_modified')).to eq origin_last_modified
      end
    end
  end
end
