module Determinator
  module Retrieve
    class NullRetriever
      # This retriever is a stub which acts as if there are
      # no currently active experiments or features.
      # Use this retriever when you need to run tests in other systems.
      def initialize(discovery_url:)
      end

      # The Control class will assume a nil return from this method
      # means the feature doesn't exist, so in turn will return `false`.
      def retrieve(_)
      end
    end
  end
end
