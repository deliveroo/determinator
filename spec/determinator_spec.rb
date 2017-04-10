require "spec_helper"

describe Determinator do
  describe '::VERSION' do
    subject { described_class::VERSION }

    it { should match(%r{\A\d+\.\d+\.\d+\z}) }
  end
end
