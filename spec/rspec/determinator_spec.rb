require 'rspec/determinator'

describe RSpec::Determinator, :determinator_support do
  subject(:determinator) { Determinator.configure(retrieval: nil) }

  context 'when forcing determinations' do
    forced_determination(:mine, 'jp')

    it { }
  end
end
