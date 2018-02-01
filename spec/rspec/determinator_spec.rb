require 'rspec/determinator'

# Determinator config is always done outside tests, this
# emulates that.
Determinator.configure(retrieval: nil)

describe RSpec::Determinator, :determinator_support do
  subject(:determinator) { Determinator.instance }

  describe 'the determination for the experiment' do
    subject(:determination) { determinator.which_variant(:my_experiment, properties: properties) }
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

      it { should eq 'first outcome' }
    end

    context 'when using an ActorControl proxy' do
      let(:determinator) { Determinator.instance.for_actor(id: 123) }

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
