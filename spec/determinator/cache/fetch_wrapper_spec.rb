require 'spec_helper'
require 'active_support/cache'

RSpec.describe Determinator::Cache::FetchWrapper do
  let(:described_instance) { described_class.new(*caches) }
  let(:feature) { FactoryBot.create(:feature) }
  subject(:described_method) do
    described_instance.call(feature.name){ retrieval_response }
  end
  shared_examples "a cache" do
    context 'when the feature exists' do
      let(:retrieval_response) { feature }

      context 'when the feature is not in the cache' do
        # No setup required

        it { should eq retrieval_response }
        it 'should have performed a retrieval' do
          expect{|b| described_instance.call(feature.name, &b)}.to yield_control
        end
      end

      context 'when the feature is in the cache' do
        before do
          described_instance.call(feature.name) { retrieval_response }
        end

        it { should eq retrieval_response }
        it 'should not have performed a retrieval' do
          expect{|b| described_instance.call(feature.name, &b)}.not_to yield_control
        end
      end
    end

    context "if there is an error response" do
      let(:retrieval_response) { Determinator::ErrorResponse.new }

      it "should populate any caches" do
        [caches].flatten.each do |cache|
          expect(cache).not_to receive(:write)
        end
        subject
      end
    end

    context 'when the feature does not exist' do
      let(:retrieval_response) { Determinator::MissingResponse.new }

      context 'when the (absence of the) feature is not in the cache' do
        # No setup required

        it { should be_a Determinator::MissingResponse }
        it 'should have performed a retrieval' do
          expect{|b| described_instance.call(feature.name, &b)}.to yield_control
        end
      end

      context 'when the (absence of the) feature is in the cache' do
        before do
          described_instance.call(feature.name) { retrieval_response }
        end

        it { should be_a Determinator::MissingResponse }
        it 'should not have performed a retrieval' do
          expect{|b| described_instance.call(feature.name, &b)}.not_to yield_control
        end

        context 'and cached nils are off' do
          let(:described_instance) { described_class.new(*caches, cache_missing: false) }
          it { should eq retrieval_response }
          it 'should have performed a retrieval' do
            expect{|b| described_instance.call(feature.name, &b)}.to yield_control
          end
        end
      end
    end
  end

  describe "with two caches" do
    let(:caches) {
      [
        ActiveSupport::Cache::MemoryStore.new(expires_in: 1.minute),
        ActiveSupport::Cache::MemoryStore.new(expires_in: 1.minute)
      ]
    }
    it_behaves_like "a cache"

    context "when an item is in the lower cache" do
      before do
        caches[1].write(described_instance.send(:key, feature.name), retrieval_response)
      end
      let(:retrieval_response) { feature }

      it { should eq retrieval_response }

      it "should populate the upper cache" do
        expect(caches[1]).not_to receive(:write)
        expect(caches[0]).to receive(:write).once
        subject
      end

      it 'should not have performed a retrieval' do
        expect{|b| described_instance.call(feature.name, &b)}.not_to yield_control
        subject
      end
    end
  end

  describe "with one cache" do
    let(:caches) { ActiveSupport::Cache::MemoryStore.new(expires_in: 1.minute) }
    it_behaves_like "a cache"
  end
end
