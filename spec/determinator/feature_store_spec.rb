require 'spec_helper'

describe Determinator::FeatureStore do
  let(:instance) { described_class.new(
    storage: storage,
    retrieval: retrieval,
    cache_timeout: cache_timeout
  ) }
  let(:storage) { double }
  let(:retrieval) { double }
  let(:cache_timeout) { 10 }

  describe '#features' do
    subject(:method_call) { instance.features }

    it 'should return the all features reported by storage' do
      allow(storage).to receive(:get_all).and_return(:array_of_features)
      expect(method_call).to eq :array_of_features
    end
  end

  describe '#feature' do
    subject(:method_call) { instance.feature(feature_name) }
    let(:feature_name) { '1' }

    before { allow(storage).to receive(:get).with(feature_name).and_return(feature) }

    context 'when the feature exists in storage' do
      let(:feature) { FactoryGirl.create(:feature, name: feature_name) }

      context 'when the cache is empty' do
        before { instance.flush_cache! }

        it { should eq feature }

        it 'should populate the cache' do
          method_call
          expect(instance.instance_variable_get('@feature_cache')).to eq({ feature_name => feature })
        end

        it 'should set the earliest_cache_entry to now' do
          method_call
          expect(instance.instance_variable_get('@earliest_cache_entry')).to be_within(0.5).of(Time.now)
        end
      end

      context 'when the cache has details for this feature' do
        before do
          instance.instance_variable_set('@feature_cache', { feature_name => feature })
          instance.instance_variable_set('@earliest_cache_entry', Time.now - cache_age)
        end

        context 'when the cache is valid' do
          let(:cache_age) { 0 }

          it { should eq feature }

          it 'should not hit storage' do
            expect(storage).to_not receive(:get)
            method_call
          end
        end

        context 'when the cache has expired' do
          let(:cache_age) { cache_timeout * 2 }

          it { should eq feature }

          it 'should retrieve from storage' do
            expect(storage).to receive(:get)
            method_call
          end
        end
      end
    end

    context 'when the feature does not exist in storage' do
      let(:feature) { nil }

      it { should be_nil }

      it 'should populate the cache with the miss' do
        method_call
        expect(instance.instance_variable_get('@feature_cache')).to eq({ feature_name => feature })
      end
    end
  end
end
