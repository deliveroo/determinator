require "spec_helper"

describe Determinator::Control do
  let(:instance) { described_class.new(feature_store: feature_store) }
  let(:feature_store) { double }
  let(:feature_name) { 'name' }
  let(:feature_seed) { feature_name }
  let(:feature_constraints) { {} }
  let(:feature) { nil }

  # Defaults
  let(:actor_constraints) { {} }
  let(:guid) { 'abc' }
  let(:id) { '123' }
  let(:overrides) { {} }
  let(:rollout) { 65_536 }
  # For the default seed and id this is the lowest rollout percentage
  let(:not_quite_enough_rollout) { 2_024 }

  before do
    allow(feature_store).to receive(:feature).with(feature_name).and_return(feature)
  end

  describe '#for_actor' do
    it 'should pass all given parameters to wrapper class' do
      expect(Determinator::ActorControl).to receive(:new).with(
        instance,
        id: '1',
        guid: '2',
        default_constraints: { c: '3' }
      )
      instance.for_actor(
        id: '1',
        guid: '2',
        default_constraints: { c: '3' }
      )
    end

    it 'should provide default arguments' do
      expect(Determinator::ActorControl).to receive(:new).with(
        instance,
        id: nil,
        guid: nil,
        default_constraints: {}
      )
      instance.for_actor
    end
  end

  shared_examples 'for various actor constraints' do |match_value|
    context "when the actor constraints do match" do
      let(:actor_constraints) { { a: '1' } }

      it { should eq match_value }
    end

    context "when the actor constraints don't match" do
      let(:actor_constraints) { { a: '2' } }

      it { should eq false }
    end

    context "when the actor constraints coincide" do
      let(:actor_constraints) { { a: ['1', '3'] } }

      it { should eq match_value }
    end
  end

  shared_examples 'a feature with seed responses' do |responses|
    context 'when the rollout is just enough to reach this actor' do
      let(:rollout) { not_quite_enough_rollout + 1 }

      it { should eq responses[:name] }

      context 'when the given actor has an override value set' do
        let(:overrides) { { id => false } }

        it { should eq false }
      end
    end

    context "when the rollout is't quite enough to reach this actor" do
      let(:rollout) { not_quite_enough_rollout }

      it { should eq false }
    end

    context 'when the feature has a different seed' do
      let(:feature_seed) { 'another' }
      let(:not_quite_enough_rollout) { 61_820 }

      context 'when the rollout is just enough to reach this actor' do
        let(:rollout) { not_quite_enough_rollout + 1 }

        it { should eq responses[:another] }
      end

      context "when the rollout is't quite enough to reach this actor" do
        let(:rollout) { not_quite_enough_rollout }

        it { should eq false }
      end
    end

    context "when the feature has one target group with one constraint" do
      let(:feature_constraints) { { a: '1' } }

      include_examples 'for various actor constraints', responses[:name]
    end

    context "when the feature has one target group with multiple constraints in one scope" do
      let(:feature_constraints) { { a: ['1', '4'] } }

      include_examples 'for various actor constraints', responses[:name]
    end

    context "when the requested feature doesn't exist" do
      let(:feature) { nil }

      it { should eq false }
    end
  end

  # Tests for features
  describe '#show_feature?' do
    subject(:method_call) { instance.show_feature?(
      feature_name,
      id: id,
      guid: guid,
      constraints: actor_constraints
    ) }
    let(:feature) { FactoryGirl.create(:feature,
      name: feature_name,
      seed: feature_seed,
      overrides: overrides,
      rollout: rollout,
      constraints: feature_constraints
    ) }

    it_behaves_like 'a feature with seed responses', name: true, another: true

    context 'when the requested feature is not a feature, but a fully rolled out experiment' do
      let(:feature) { FactoryGirl.create(:experiment, :full_rollout) }

      it { should eq false }
    end
  end

  # Tests for experiments
  describe '#which_variant' do
    subject(:method_call) { instance.which_variant(
      feature_name,
      id: id,
      guid: guid,
      constraints: actor_constraints
    ) }
    let(:feature) { FactoryGirl.create(:experiment,
      name: feature_name,
      seed: feature_seed,
      overrides: overrides,
      rollout: rollout,
      constraints: feature_constraints
    ) }

    it_behaves_like 'a feature with seed responses', name: 'b', another: 'a'

    context 'when the requested feature is not an experiment, but a fully rolled out feature' do
      let(:feature) { FactoryGirl.create(:feature, :full_rollout) }

      it { should eq false }
    end
  end
end
