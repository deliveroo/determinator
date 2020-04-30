require 'spec_helper'
require 'determinator/retrieve/null_retriever'

describe Determinator::Retrieve::NullRetriever do
  let(:discovery_url) { '' }

  subject { described_class.new(discovery_url: discovery_url) }

  describe '#retrieve' do
    it 'should just return nil' do
      expect(subject.retrieve(anything)).to match an_instance_of(Determinator::MissingResponse)
    end
  end

end
