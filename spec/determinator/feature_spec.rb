require 'spec_helper'

describe Determinator::Feature do
  describe '#experiment?' do
    subject(:method_call) { instance.experiment? }

    context 'when the feature is an experiment' do
      let(:instance) { FactoryBot.create(:experiment) }

      it { should eq true }
    end

    context 'when the feature is not an experiment' do
      let(:instance) { FactoryBot.create(:feature) }

      it { should eq false }
    end
  end

  describe '#feature_flag?' do
    subject(:method_call) { instance.feature_flag? }

    context 'when the feature is an experiment' do
      let(:instance) { FactoryBot.create(:experiment) }

      it { should eq false }
    end

    context 'when the feature is not an experiment' do
      let(:instance) { FactoryBot.create(:feature) }

      it { should eq true }
    end
  end

  describe '#active?' do
    subject { feature.active? }

    context 'when feature is active' do
      let(:feature) { FactoryBot.create(:feature, :active) }

      it { should be_truthy }
    end

    context 'when feature is inactive' do
      let(:feature) { FactoryBot.create(:feature) }

      it { should be_falsey }
    end
  end

  describe '#structured?' do
    subject { feature.structured? }

    context 'when feature is not structured' do
      let(:feature) { FactoryBot.create(:feature) }

      it { should eq false }

      context 'when structured_bucket is an empty string' do
        let(:feature) { FactoryBot.create(:feature, structured_bucket: '') }

        it { should eq false }
      end
    end

    context 'when feature is structured' do
      let(:feature) { FactoryBot.create(:feature, :structured) }

      it { should eq true }
    end
  end

  describe 'when a fixed determination is present' do
    let(:instance) { FactoryBot.create(:experiment, fixed_determinations: [fixed_determination]) }

    context 'when the variant is not present in the variants' do
      let(:fixed_determination) { {'feature_on' => true, 'variant' => 'c', 'constraints' => {}} }

      it 'should be ignored' do
        expect(instance.fixed_determinations).to be_empty
      end
    end

    context 'when a variant is present and the fixed determination is not on' do
      let(:fixed_determination) { {'feature_on' => false, 'variant' => 'a', 'constraints' => {}} }

      it 'should be ignored' do
        expect(instance.fixed_determinations).to be_empty
      end
    end

    context 'when the variant is blank' do
      let(:fixed_determination) { {'feature_on' => true, 'variant' => '', 'constraints' => {}} }

      it 'should not be ignored' do
        expect(instance.fixed_determinations.first.feature_on).to eq(true)
      end
    end
  end
end
