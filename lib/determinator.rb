require 'determinator/version'
require 'determinator/control'
require 'determinator/feature'
require 'determinator/target_group'
require 'determinator/fixed_determination'
require 'determinator/explainer'
require 'determinator/cache/fetch_wrapper'
require 'determinator/serializers/json'
require 'determinator/missing_response'
require 'determinator/error_response'
require 'determinator/tracking'


module Determinator
  class << self
    attr_reader :feature_cache, :retrieval
    # @param :retrieval [Determinator::Retrieve::Routemaster] A retrieval instance for Features
    # @param :errors [#call, nil] a proc, accepting an error, which will be called with any errors which occur while determinating
    # @param :missing_feature [#call, nil] a proc, accepting a feature name, which will be called any time a feature is requested but isn't available
    # @param :feature_cache [#call] a caching proc, accepting a feature name, which will return the named feature or yield (and store) if not available
    def configure(retrieval:, errors: nil, missing_feature: nil, feature_cache:)
      self.on_error(&errors) if errors
      self.on_missing_feature(&missing_feature) if missing_feature
      @feature_cache = feature_cache
      @retrieval = retrieval
      @instance = Control.new(retrieval: retrieval)
    end

    # Returns the currently configured Determinator::Control instance
    #
    # @return [Determinator::Control] The currently active instance of determinator.
    # @raises [RuntimeError] If no Determinator instance is set up (with `.configure`)
    def instance
      raise "No singleton Determinator instance defined" unless @instance
      @instance
    end

    # Defines how errors that shouldn't break your application should be logged
    def on_error(&block)
      @error_logger = block
    end

    # Defines how to record the moment when a feature which doesn't exist is requested.
    # If this happens a lot it indicates poor set up, so can be useful for tracking.
    def on_missing_feature(&block)
      @missing_feature_logger = block
    end

    # Defines code that should execute when a determination is completed. This is particularly
    # helpful for preparing or sending events to record that an actor has seen a particular experiment variant.
    #
    # Please note that this block will be executed _synchronously_ before delivering the determination to the callsite.
    #
    # @yield [id, guid, feature, determination] Will be called when a determination was requested for the
    #   specified `feature`, for the actor with `id` and `guid`, and received the determination `determination`.
    # @yieldparam id [String, nil] The ID that was used to request the determination
    # @yieldparam guid [String, nil] The GUID that was used to request the determination
    # @yieldparam feature [Determinator::Feature] The feature that was requested
    # @yieldparam determination [String,Boolean] The result of the determination
    def on_determination(&block)
      @determination_callback = block
    end

    # Returns the feature with the given name as Determinator uses it. This is useful for
    # debugging issues with the retrieval mechanism which delivers features to Determinator.
    # @returns [Determinator::Feature,nil] The feature details Determinator would use for a determination right now.
    def feature_details(name)
      with_retrieval_cache(name) { instance.retrieval.retrieve(name) }
    end

    # Allows Determinator to track that an error has happened with determination
    # @api private
    def notice_error(error)
      return unless @error_logger

      error = RuntimeError.new(error) unless error.is_a?(StandardError)
      @error_logger.call(error)
    end

    # Allows Determinator to track that a feature was requested but was missing
    # @api private
    def notice_missing_feature(name)
      return unless @missing_feature_logger

      @missing_feature_logger.call(name)
    end

    def notice_determination(id, guid, feature, determination)
      Determinator::Tracking.track(id, guid, feature, determination)
      return unless @determination_callback
      @determination_callback.call(id, guid, feature, determination)
    end

    # Allows access to the chosen caching mechanism for any retrieval plugin.
    # @api private
    def with_retrieval_cache(name)
      return yield unless @feature_cache.respond_to?(:call)

      @feature_cache.call(name) { yield }
    end

    def invalidate_cache(name)
      @feature_cache.expire(name)
    end
  end
end
