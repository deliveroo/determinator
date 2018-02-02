require 'active_support/cache'

module Determinator
  module Cache
    class ActiveSupportMemoryStore
      def initialize(**args)
        @active_support_cache = ActiveSupport::Cache::MemoryStore.new(**args)
      end

      def call(feature_name)
        @active_support_cache.fetch(key(feature_name)) { yield }
      end

      private

      def key(feature_name)
        "determinator:feature_cache:#{feature_name}"
      end
    end
  end
end
