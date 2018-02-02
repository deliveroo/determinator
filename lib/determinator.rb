require 'determinator/version'
require 'determinator/control'
require 'determinator/feature'
require 'determinator/target_group'
require 'determinator/retrieve/routemaster'
require 'determinator/retrieve/null_retriever'

module Determinator
  class << self
    # @param :retrieval [Determinator::Retrieve::Routemaster] A retrieval instance for Features
    # @param :errors [#call, nil] a proc, accepting an error, which will be called with any errors which occur while determinating
    # @param :missing_feature [#call, nil] a proc, accepting a feature name, which will be called any time a feature is requested but isn't available
    def configure(retrieval:, errors: nil, missing_feature: nil)
      self.on_error_logger(&errors) if errors
      self.on_missing_feature(&missing_feature) if missing_feature
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
    
    # Returns the feature with the given name as Determinator uses it. This is useful for
    # debugging issues with the retrieval mechanism which delivers features to Determinator.
    # @returns [Determinator::Feature,nil] The feature details Determinator would use for a determination right now.
    def feature_details(name)
      instance.retrieval.retrieve(name)
    end

    def notice_error(error)
      return unless @error_logger

      error = RuntimeError.new(error) unless error.is_a?(StandardError)
      @error_logger.call(error)
    end

    def notice_missing_feature(name)
      return unless @missing_feature_logger

      @missing_feature_logger.call(name)
    end
  end
end
