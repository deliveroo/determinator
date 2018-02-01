require 'determinator'

module RSpec
  module Determinator
    def self.included(by)
      by.extend(DSL)

      by.let(:fake_determinator) { FakeControl.new }
      by.before do
        allow(::Determinator).to receive(:instance).and_return(fake_determinator)
      end
    end

    module DSL
      # Ensure that for the duration of the example all determinations made for the given experiment or feature flag
      # will have the given outcome (but only if the constraints specified are met exactly).
      #
      # If `outcome` or `only_for` are Symbols then the example-scoped variable of that name will be referenced (ie. those
      # variables created by `let` declarations)
      #
      # @params name [#to_s] The name of the Feature Flag or Experiment to mock
      # @params outcome [Boolean,String,Symbol] The outcome which should be supplied. Will look up an example variable if a Symbol is given.
      # @params :only_for [Hash,Symbol] The constraints that must be matched exactly in order for the determination to be applied.
      def forced_determination(name, outcome, only_for: {})
        before do
          outcome = send(outcome) if outcome.is_a?(Symbol)
          only_for = send(only_for) if only_for.is_a?(Symbol)

          fake_determinator.mock_result(
            name,
            outcome,
            only_for: only_for
          )
        end
      end
    end

    class FakeControl
      def initialize
        @mocked_results = Hash.new { |h, k| h[k] = {} }
      end

      def for_actor(**args)
        ::Determinator::ActorControl.new(self, **args)
      end

      def mock_result(name, result, only_for: {})
        @mocked_results[name.to_s][only_for] = result
      end

      def fake_determinate(name, id: nil, guid: nil, properties: {})
        properties[:id] = id if id
        properties[:guid] = guid if guid

        outcome_for_feature_given_properties(name.to_s, properties)
      end
      alias_method :feature_flag_on?, :fake_determinate
      alias_method :which_variant, :fake_determinate

      private

      def outcome_for_feature_given_properties(feature_name, requirements)
        req_array = requirements.to_a

        _, forced = @mocked_results[feature_name].find do |given, outcome|
          (given.to_a - req_array).empty?
        end

        forced || false
      end
    end
  end
end

RSpec.configure do |conf|
  conf.include RSpec::Determinator, :determinator_support
end
