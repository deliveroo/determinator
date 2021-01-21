require 'rspec/determinator'

# Determinator config is always done outside tests, this
# emulates that.
Determinator.configure(retrieval: nil, feature_cache: RSpec::Determinator::DO_NOT_USE_IN_PRODUCTION_CODE_NULL_FEATURE_CACHE)

describe RSpec::Determinator, :determinator_support do
  subject(:determinator) { Determinator.instance }

  describe 'the determination for the experiment' do
    subject(:determination) { determinator.which_variant(:my_experiment, id: id, guid: guid, properties: properties) }
    let(:id) { nil }
    let(:guid) { nil }
    let(:properties) { {} }

    context 'when not forcing a determination' do
      it { should eq false }
    end

    context 'when forcing a determination' do
      forced_determination(:my_experiment, 'outcome')

      it { should eq 'outcome' }
    end

    context 'when forcing a determination with an example-scoped variable for the outcome' do
      forced_determination(:my_experiment, :outcome)
      let(:outcome) { 'some_outcome' }

      it { should eq 'some_outcome' }
    end

    context 'when forcing a determination for actors with specific properties that match' do
      forced_determination(:my_experiment, 'outcome', only_for: { property: 'correct' })
      let(:properties) { { property: 'correct' } }

      it { should eq 'outcome' }
    end

    context 'when forcing a determination for actors with specific numeric properties' do
      forced_determination(:my_experiment, 'outcome', only_for: { 1 => 2 })
      let(:properties) { { 1 => 2 } }

      it { should eq 'outcome' }
    end

    context 'when forcing a determination for actors with specific properties that match when the forced determination needs to be normalized' do
      forced_determination(:my_experiment, 'outcome', only_for: { 'property' => 'correct' })
      let(:properties) { { property: 'correct' } }

      it { should eq 'outcome' }
    end

    context 'when forcing a determination for actors with specific properties that match when the determination needs to be normalized' do
      forced_determination(:my_experiment, 'outcome', only_for: { property: 'correct' })
      let(:properties) { { 'property' => 'correct' } }

      it { should eq 'outcome' }
    end

    context 'when forcing a determination for actors with specific properties that match when using an example-scoped variable for constraints' do
      forced_determination(:my_experiment, 'outcome', only_for: :properties)
      let(:properties) { { property: 'correct' } }

      it { should eq 'outcome' }
    end

    context 'when forcing a determination for actors with specific properties that do not match' do
      forced_determination(:my_experiment, 'outcome', only_for: { property: 'incorrect' })
      let(:properties) { { property: 'correct' } }

      it { should eq false }
    end

    context 'when forcing a determination for actors with specific properties that match enough' do
      forced_determination(:my_experiment, 'outcome', only_for: { property: 'correct' })
      let(:properties) { { property: 'correct', extra: 'also present' } }

      it { should eq 'outcome' }
    end

    context 'when forcing more than one matching determination' do
      forced_determination(:my_experiment, 'first outcome', only_for: { property: 'correct' })
      forced_determination(:my_experiment, 'second outcome', only_for: { extra: 'also present' })

      let(:properties) { { property: 'correct', extra: 'also present' } }

      it { should eq 'second outcome' }
    end

    context 'when forcing a determination for array constraints' do
      forced_determination(:my_experiment, 'outcome', only_for: { attribute: %w(thing-a thing-b) })
      let(:properties) { { attribute: 'thing-b' } }

      it { should eq 'outcome' }
    end

    context 'when forcing a determination for array constraints' do
      forced_determination(:my_experiment, 'outcome', only_for: { attribute: %w(thing-a thing-b) })
      let(:properties) { { attribute: 'thing-b' } }

      it { should eq 'outcome' }
    end

    context 'when using an ActorControl proxy' do
      let(:determinator) { Determinator.instance.for_actor(id: 123) }
      subject(:determination) { determinator.which_variant(:my_experiment, properties: properties) }

      context 'when not forcing a determination' do
        it { should eq false }
      end

      context 'when forcing a determination' do
        forced_determination(:my_experiment, 'outcome')

        it { should eq 'outcome' }
      end
    end
  end
end
