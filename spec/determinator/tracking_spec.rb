require "spec_helper"
require 'determinator/tracking'

describe Determinator::Tracking do
  after do
    described_class.clear!
  end

  describe '.instance' do
    context 'not started' do
      specify { expect(described_class.instance).to be_nil }
    end

    context 'started' do
      before do
        described_class.start!(:test)
      end

      specify { expect(described_class.instance).to be_a(Determinator::Tracking::Tracker) }
    end
  end

  describe '.start' do
    it 'returns a tracker' do
      expect(described_class.start!(:test)).to be_a(Determinator::Tracking::Tracker)
    end

    it 'sets the type' do
      expect(described_class.start!(:test).type).to eq(:test)
    end

    it 'sets the instance' do
      expect { described_class.start!(:test) }.to change{ described_class.instance }.from(nil)
    end
  end

  describe '.finish!' do
    context 'when not started' do
      it 'returns false' do
        expect(described_class.finish!(error: true) ).to eq(false)
      end
    end

    context 'when started' do
      let(:feature) { FactoryGirl.build(:feature, name: 'test_feature') }

      before do
        described_class.start!(:test)
        described_class.track(123, 'abc', feature, 'A')
      end

      it 'returns a request' do
        expect(described_class.finish!(error: false, foo: :bar)).to be_a(Determinator::Tracking::Request)
      end

      it 'sets the error status' do
        expect(described_class.finish!(error: true, foo: :bar).error).to eq(true)
      end

      it 'sets the type' do
        expect(described_class.finish!(error: false, foo: :bar).type).to eq(:test)
      end

      it 'sets the attributes' do
        expect(described_class.finish!(error: false, foo: :bar).attributes).to eq({foo: :bar})
      end

      context 'when reporting is enabled' do
        before do
          $_test_request = nil
          described_class.on_request{ |r| $_test_request = r }
        end

        after do
          described_class.clear_on_request!
        end

        it 'calls the reporter' do
          expect{ described_class.finish!(error: false, foo: :bar) }.to change{ $_test_request }
            .from(nil)
            .to(instance_of(Determinator::Tracking::Request))
        end
      end
    end
  end
end
