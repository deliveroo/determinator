require 'spec_helper'

RSpec.describe Determinator::Cache::FetchWrapper do
  describe '#call' do
    subject(:described_method) do
      @retrieval_called = false
      described_instance.call(feature.name) do
        @retrieval_called = true
        retrieval_response
      end
    end
    let(:described_instance) { described_class.new(cache) }
    let(:cache) { ActiveSupport::Cache::MemoryStore.new(expires_in: 1.minute) }
    let(:feature) { FactoryGirl.create(:feature) }

    context 'when the feature exists' do
      let(:retrieval_response) { feature }

      context 'when the feature is not in the cache' do
        # No setup required

        it { should eq retrieval_response }
        it 'should have performed a retrieval' do
          subject
          expect(@retrieval_called).to be true
        end
      end

      context 'when the feature is in the cache' do
        before do
          described_instance.call(feature.name) { retrieval_response }
        end

        it { should eq retrieval_response }
        it 'should not have performed a retrieval' do
          subject
          expect(@retrieval_called).to be false
        end
      end
    end

    context 'when the feature does not exist' do
      let(:retrieval_response) { nil }

      context 'when the (absence of the) feature is not in the cache' do
        # No setup required

        it { should eq retrieval_response }
        it 'should have performed a retrieval' do
          subject
          expect(@retrieval_called).to be true
        end
      end

      context 'when the (absence of the) feature is in the cache' do
        before do
          described_instance.call(feature.name) { retrieval_response }
        end

        it { should eq retrieval_response }
        it 'should not have performed a retrieval' do
          subject
          expect(@retrieval_called).to be false
        end
      end
    end
  end
end
