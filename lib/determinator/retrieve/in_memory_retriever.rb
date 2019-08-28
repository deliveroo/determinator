module Determinator
  module Retrieve

    # An retriever that returns features that were previously stored
    # in the retriever. Useful for testing.
    class InMemoryRetriever
      def initialize
        @features = {}
      end

      # @param name [string,symbol] The name of the feature to retrieve
      def retrieve(name)
        @features[name.to_s]
      end

      # @param feature [Determinator::Feature] The feature to store
      def store(feature)
        @features[feature.name] = feature
      end

      def clear!
        @features.clear
      end
    end

  end
end
