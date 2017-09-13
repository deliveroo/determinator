require 'rspec/determinator'

describe RSpec::Determinator, :determinator_support do
  subject(:determinator) { Determinator.configure(retrieval: nil) }

  describe 'the determination for the experiment' do
    subject(:determination) { determinator.which_variant(:my_experiment, constraints: constraints) }
    let(:constraints) { {} }

    context 'when not forcing a determination' do
      it { should eq false }
    end

    context 'when forcing a determination' do
      forced_determination(:my_experiment, 'outcome')

      it { should eq 'outcome' }
    end

    context 'when forcing a determination for actors with specific properties that match' do
      forced_determination(:my_experiment, 'outcome', only_for: { property: 'correct' })
      let(:constraints) { { property: 'correct' } }

      it { should eq 'outcome' }
    end

    context 'when forcing a determination for actors with specific properties that do not match' do
      forced_determination(:my_experiment, 'outcome', only_for: { property: 'incorrect' })
      let(:constraints) { { property: 'correct' } }

      it { should eq false }
    end

    context 'when forcing a determination for actors with specific properties that match enough' do
      forced_determination(:my_experiment, 'outcome', only_for: { property: 'correct' })
      let(:constraints) { { property: 'correct', extra: 'also present' } }

      it { should eq 'outcome' }
    end

    context 'when forcing more than one matching determination' do
      forced_determination(:my_experiment, 'first outcome', only_for: { property: 'correct' })
      forced_determination(:my_experiment, 'second outcome', only_for: { extra: 'also present' })

      let(:constraints) { { property: 'correct', extra: 'also present' } }

      it { should eq 'first outcome' }
    end
  end
end
