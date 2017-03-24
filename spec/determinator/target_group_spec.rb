require 'spec_helper'

describe Determinator::TargetGroup do
  let(:instance) { described_class.new(rollout: rollout, constraints: constraints) }
  let(:rollout) { 32_768 }
  let(:constraints) { {} }

  describe '#rollout_percent' do
    subject(:method_call) { instance.rollout_percent }

    it { should eq Rational(rollout, 65_536) }
  end
end
