module Determinator
  module Cache
    class FetchWrapper
      # @param *caches [ActiveSupport::Cache] If a list then the head of the the
      # list should will be checked before the  tail. If the head is empty but
      # the tail is not then the head will be filled with the value of the tail.
      def initialize(*caches, cache_missing: true)
        @cache_missing = cache_missing
        @caches = caches
        @mutex = Mutex.new
      end

      # Call walks through each cache, returning a value if the item exists in
      # any cache, otherwise popularing each cache with the value of yield.
      def call(feature_name)
        @mutex.synchronize do
          value = read_and_upfill(feature_name)

          # if the value is missing and we cache it, return the missing response
          return value if value.is_a?(MissingResponse) && @cache_missing

          #otherwise only return the non nil/notice_missing_feature value
          return value if !value.nil? && !(value.is_a?(MissingResponse) && !@cache_missing)

          value_to_write = yield
          return value_to_write if value_to_write.is_a?(ErrorResponse)

          @caches.each do |cache|
            cache.write(key(feature_name), value_to_write)
          end

          return value_to_write
        end
      end

      def expire(feature_name)
        @mutex.synchronize do
          @caches.each{ |c| c.delete(key(feature_name)) }
        end
      end

      private

      def key(feature_name)
        "determinator:feature_cache:#{feature_name}"
      end

      # Walks through the list of caches, returning the first stored value.
      #
      # If a value is found in a cache after the first then all caches earlier
      # in that list will be backfilled.
      #
      # @param url [String] a feature name
      # @return [Feature, MissingResponse] nil when no value is found
      def read_and_upfill(feature_name)
        @caches.each.with_index do |cache, index|
          if cache.exist?(key(feature_name))
            value = cache.read(key(feature_name))
            @caches[0...index].each do |cache|
              cache.write(key(feature_name), value)
            end
            return value
          end
        end
        return nil
      end
    end
  end
end
