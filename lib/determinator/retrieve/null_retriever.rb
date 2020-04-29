module Determinator
  module Retrieve
    # This retriever is a stub which acts as if there are
    # no currently active experiments or features.
    # Use this retriever when you need to run tests in other systems.
    class NullRetriever
      def initialize(discovery_url:)
      end

      # The Control class will assume a nil return from this method
      # means the feature doesn't exist, so in turn will return `false`.
      def retrieve(_)
        MissingResponse.new
      end
    end
  end
end
