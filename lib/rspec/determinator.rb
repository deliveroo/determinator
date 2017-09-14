require 'determinator'

module RSpec
  module Determinator
    def self.included(by)
      by.extend(DSL)

      by.let(:fake_determinator) { FakeControl.new }
      by.before do
        allow(::Determinator::Control).to receive(:new).and_return(fake_determinator)
      end
    end

    module DSL
      def forced_determination(name, result, only_for: {})
        before do
          fake_determinator.mock_result(
            name,
            result,
            only_for: only_for
          )
        end
      end
    end

    class FakeControl
      def initialize
        @mocked_results = Hash.new { |h, k| h[k] = {} }
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
