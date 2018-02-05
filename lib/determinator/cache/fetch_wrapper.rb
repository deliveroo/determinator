module Determinator
  module Cache
    class FetchWrapper
      # @param cache [#fetch] An instance of a cache class which implements #fetch like ActiveSupport::Cache does
      def initialize(cache)
        @cache = cache
      end

      def call(feature_name)
        @cache.fetch(key(feature_name)) { yield }
      end

      private

      def key(feature_name)
        "determinator:feature_cache:#{feature_name}"
      end
    end
  end
end
