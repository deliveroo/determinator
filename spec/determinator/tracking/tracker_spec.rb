require "spec_helper"
require 'determinator/tracking/tracker'

describe Determinator::Tracking::Tracker do
  let(:type) { :test }
  subject{ described_class.new(type) }

  describe '#track' do
    let(:feature) { FactoryGirl.build(:feature, name: 'test_feature') }
    let(:perform) { subject.track(123, 'abc', feature, 'A') }

    it 'enqueues a determination' do
      expect { perform }.to change { subject.determinations.length }.by(1)
    end

    it 'sets the correct parameters' do
      expect{ perform }.to change{ subject.determinations.first }
        .from(nil)
        .to(Determinator::Tracking::Determination.new(id: 123, guid: 'abc', feature_id: 'test_feature', determination: 'A'))
    end
  end

  describe '#finish!' do
    let(:feature) { FactoryGirl.build(:feature, name: 'test_feature') }
    let(:perform) { subject.finish!(endpoint: 'test', error: true, foo: :bar) }

    before do
      allow(Process).to receive(:clock_gettime).and_return(1.0, 3.0)
      subject.track(123, 'abc', feature, 'A')
    end

    it 'returns a request' do
      expect(perform).to be_a(Determinator::Tracking::Request)
    end

    specify { expect(perform.start).to eq(1.0)}
    specify { expect(perform.type).to eq(:test) }
    specify { expect(perform.endpoint).to eq('test') }
    specify { expect(perform.time).to eq(2.0) }
    specify { expect(perform.error).to eq(true) }
    specify { expect(perform.attributes).to eq({foo: :bar}) }
    specify { expect(perform.determinations.length).to eq(1) }
  end
end
