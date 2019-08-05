require 'determinator'
require_relative '../determinator/retrieve/in_memory_retriever'

module RSpec
  module Determinator
    def self.included(by)
      by.extend(DSL)

      by.let(:fake_retriever) { ::Determinator::Retrieve::InMemoryRetriever.new }
      by.around do |example|
        old_retriever = ::Determinator.instance.retrieval
        begin
          fake_retriever.clear!
          ::Determinator.configure(retrieval: fake_retriever)
          example.run
        ensure
          ::Determinator.configure(retrieval: old_retriever)
        end
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

          active = !!outcome
          variants = case outcome
                     when true, false then
                       []
                     else
                       { outcome => 1 }
                     end
          target_group = ::Determinator::TargetGroup.new(
            rollout: 65_536,
            constraints: Hash[only_for.map { |key, value| [key.to_s, value] }]
          )

          feature = ::Determinator::Feature.new(
            name: name.to_s,
            identifier: name.to_s,
            bucket_type: 'single',
            active: active,
            variants: variants,
            target_groups: [target_group]
          )

          fake_retriever.store(feature)
        end
      end
    end
  end
end

RSpec.configure do |conf|
  conf.include RSpec::Determinator, :determinator_support
end
