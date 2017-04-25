require "spec_helper"

describe Determinator::Retrieve::NullRetriever do
  let(:discovery_url) { '' }

  subject { described_class.new(discovery_url: discovery_url) }

  describe '#retrieve' do
    it 'should just return nil' do
      expect(subject.retrieve(anything)).to be_nil
    end
  end

end
