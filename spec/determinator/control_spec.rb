require "spec_helper"

describe Determinator::Control do
  let(:instance) { described_class.new(retrieval: retrieval) }
  let(:retrieval) { double }
  let(:feature_name) { 'name' }
  let(:feature_identifier) { feature_name }
  let(:feature_constraints) { {} }
  let(:feature) { nil }

  # Defaults
  let(:actor_constraints) { {} }
  let(:guid) { 'abc' }
  let(:id) { '123' }
  let(:bucket_type) { :guid }
  let(:overrides) { {} }
  let(:rollout) { 65_536 }
  # For the default identifier and id this is the lowest rollout percentage
  let(:not_quite_enough_rollout) { 2_024 }
  let(:winning_variant) { 'enabled' }

  before do
    allow(retrieval).to receive(:retrieve).with(feature_name).and_return(feature)
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

  shared_examples 'a feature with identifier responses' do |responses|
    context 'when the rollout is just enough to reach this actor' do
      let(:rollout) { not_quite_enough_rollout + 1 }

      it { should eq responses[:name] }

      context 'when the given actor has an override value set' do
        let(:overrides) { { id => false } }

        it { should eq false }
      end
    end

    context "when the rollout isn't quite enough to reach this actor" do
      let(:rollout) { not_quite_enough_rollout }

      it { should eq false }
    end

    context 'when the feature has a different identifier' do
      let(:feature_identifier) { 'another' }
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

    context 'when the bucket type is id' do
      let(:bucket_type) { :id }

      context "when an actor id is given" do
        let(:id) { '1' }

        it { should eq responses[:name] }
      end

      context "when no actor id is given" do
        let(:id) { nil }

        it { should eq false }
      end
    end

    context 'when the bucket type is guid' do
      let(:bucket_type) { :guid }

      context "when an actor guid is given" do
        let(:guid) { 'abc' }

        it { should eq responses[:name] }
      end

      context "when no actor id is given" do
        let(:guid) { nil }

        it { should eq false }
      end
    end

    context 'when the bucket type is fallback' do
      let(:bucket_type) { :fallback }

      context "when an actor id is given" do
        let(:id) { '123' }

        it 'should respond as it would with the actor identifier being the id' do
          should eq responses[:another]
        end
      end

      context "when no actor id is given" do
        let(:id) { nil }

        it 'should respond as it would with the actor identifier being the guid' do
          should eq responses[:name]
        end
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
  describe '#feature_flag_on?' do
    subject(:method_call) { instance.feature_flag_on?(
      feature_name,
      id: id,
      guid: guid,
      constraints: actor_constraints
    ) }
    let(:feature) { FactoryGirl.create(:feature,
      name: feature_name,
      identifier: feature_identifier,
      bucket_type: bucket_type,
      overrides: overrides,
      rollout: rollout,
      constraints: feature_constraints
    ) }

    it_behaves_like 'a feature with identifier responses', name: true, another: true

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
      identifier: feature_identifier,
      bucket_type: bucket_type,
      overrides: overrides,
      rollout: rollout,
      constraints: feature_constraints
    ) }

    it_behaves_like 'a feature with identifier responses', name: 'b', another: 'a'

    context 'when the requested feature is not an experiment, but a fully rolled out feature' do
      let(:feature) { FactoryGirl.create(:feature, :full_rollout) }

      it { should eq false }
    end

    context 'when a winning variant is set' do
      let(:winning_variant) { 'enabled' }

      let(:feature) { FactoryGirl.create(:experiment,
        name: feature_name,
        identifier: feature_identifier,
        bucket_type: bucket_type,
        overrides: overrides,
        rollout: rollout,
        constraints: feature_constraints,
        winning_variant: winning_variant
      ) }

      subject(:method_call) { instance.which_variant(
        feature_name,
        id: id,
        guid: guid,
        constraints: actor_constraints
      ) }

      it 'is the winning variant' do
        expect(subject).to eq(winning_variant)
      end

    end
  end
end
