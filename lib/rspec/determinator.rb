require 'determinator'
require_relative '../determinator/retrieve/in_memory_retriever'

module RSpec
  module Determinator
    def self.included(by)
      by.extend(DSL)

      by.let(:fake_retriever) { ::Determinator::Retrieve::InMemoryRetriever.new }
      by.let(:fake_determinator) { ::RSpec::Determinator::FakeDeterminator.new(fake_retriever) }
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
      # @param [String,Symbol] name The name of the Feature Flag or Experiment to mock
      # @param [Boolean,String,Symbol] outcome The outcome which should be supplied. Will look up an example variable if a Symbol is given.
      # @param [Hash,Symbol] :only_for The constraints that must be matched exactly in order for the determination to be applied.
      # @param [String,Symbol] :winning_variant The winning variant. Will look up an example variable if a Symbol is given.
      # @param [Hash] :overrides
      def forced_determination(name, outcome, bucket_type: 'single', only_for: {}, winning_variant: nil, overrides: {})
        before do
          outcome = send(outcome) if outcome.is_a?(Symbol)
          only_for = send(only_for) if only_for.is_a?(Symbol)
          winning_variant = send(winning_variant) if winning_variant.is_a?(Symbol)

          ::RSpec::Determinator::FakeDeterminator.new(fake_retriever).mock_result(
            name,
            outcome,
            bucket_type: bucket_type,
            only_for: only_for,
            winning_variant: winning_variant,
            overrides: overrides,
          )
        end
      end

    end

    class FakeDeterminator

      def initialize(in_memory_retriever)
        @retriever = in_memory_retriever
      end

      VALID_BUCKET_TYPES = %w{ id guid single }.freeze

      # @param [String,Symbol] name The name of the experiment or feature flag
      # @param [Boolean,String] outcome
      # @param [String,nil] winning_variant
      # @param [Hash] overrides
      # @return [Determinator::Feature]
      def mock_result(name, outcome, bucket_type: 'single', only_for: {}, winning_variant: nil, overrides: {})
        if !VALID_BUCKET_TYPES.include?(bucket_type)
          raise ArgumentError.new("bad bucket type #{bucket_type}, expected one of: #{VALID_BUCKET_TYPES.join(' ')}")
        end

        active = !!outcome
        variants = case outcome
                   when true, false then
                     []
                   else
                     { outcome => 1 }
                   end
        target_group = ::Determinator::TargetGroup.new(
          rollout: 65_536,
          constraints: only_for.map { |key, value| [key.to_s, Array(value).map(&:to_s)] }.to_h
        )

        feature = ::Determinator::Feature.new(
          name: name.to_s,
          identifier: name.to_s,
          bucket_type: bucket_type,
          active: active,
          variants: variants,
          target_groups: [target_group],
          winning_variant: winning_variant,
          overrides: overrides,
        )

        @retriever.store(feature)

        feature
      end
    end
  end
end

RSpec.configure do |conf|
  conf.include RSpec::Determinator, :determinator_support
end
