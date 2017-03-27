module Determinator
  class FeatureStore
    def initialize(storage:, retrieval:, cache_timeout: 5)
      @storage              = storage
      @retrieval            = retrieval
      @cache_timeout        = cache_timeout
      flush_cache!
    end

    # Returns all features from storage, but does not cache them in memory
    #
    # @return [Array<Determinator::Feature>] All features from storage
    def features
      storage.get_all
    end

    # Retrieves a specific feature, by name, from the cache, falling back
    # on storage if not present or the cache has timed out.
    #
    # @param [Symbol,String] name The name of the feature requested
    # @return [Determinator::Feature,nil] The specified feature
    def feature(name)
      flush_cache_if_necessary!

      feature_name = name.to_s
      feature_cache.fetch(feature_name) do
        storage.get(feature_name).tap do |feature|
          cache_feature(feature_name, feature)
        end
      end
    end

    def retrieve(url)
      retrieval.retrieve(url).tap do |feature|
        storage.put(feature)
        cache_feature(feature)
      end
    end

    def flush_cache!
      @feature_cache = {}
      @earliest_cache_entry = nil
    end

    def flush_cache_if_necessary!
      # There are no entries in the cache
      return if earliest_cache_entry.nil?

      # The cache is still valid
      return if Time.now < earliest_cache_entry + cache_timeout

      flush_cache!
    end

    private

    attr_reader :storage, :retrieval, :feature_cache, :cache_timeout, :earliest_cache_entry

    def cache_feature(feature_name, feature)
      @earliest_cache_entry = Time.now
      feature_cache[feature_name] = feature
    end
  end
end
