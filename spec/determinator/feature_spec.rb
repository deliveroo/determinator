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

  describe '#active?' do
    subject { feature.active? }

    context 'when feature is active' do
      let(:feature) { FactoryGirl.create(:feature, :active) }

      it { should be_truthy }
    end

    context 'when feature is inactive' do
      let(:feature) { FactoryGirl.create(:feature) }

      it { should be_falsey }
    end
  end

  describe 'when a fixed determination is present' do
    let(:instance) { FactoryGirl.create(:experiment, fixed_determinations: [fixed_determination]) }
    let(:fixed_determination) { {'active' => true, 'variant' => 'c', 'constraints' => {}} }

    it 'should be ignored if the variant is not present in variants' do
      expect(instance.fixed_determinations).to be_empty
    end
  end
end
