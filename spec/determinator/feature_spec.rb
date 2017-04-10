require 'spec_helper'

describe Determinator::Feature do
  describe '#experiment?' do
    subject(:method_call) { instance.experiment? }

    context 'when the feature is an experiment' do
      let(:instance) { FactoryGirl.create(:experiment) }

      it { should eq true }
    end

    context 'when the feature is not an experiment' do
      let(:instance) { FactoryGirl.create(:feature) }

      it { should eq false }
    end
  end

  describe '#feature_flag?' do
    subject(:method_call) { instance.feature_flag? }

    context 'when the feature is an experiment' do
      let(:instance) { FactoryGirl.create(:experiment) }

      it { should eq false }
    end

    context 'when the feature is not an experiment' do
      let(:instance) { FactoryGirl.create(:feature) }

      it { should eq true }
    end
  end
end
