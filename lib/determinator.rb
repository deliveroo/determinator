require 'determinator/version'
require 'determinator/control'
require 'determinator/feature'
require 'determinator/target_group'
require 'determinator/retrieve/routemaster'
require 'determinator/retrieve/null_retriever'

module Determinator
  # @param :retrieval [Determinator::Retrieve::Routemaster] A retrieval instance for Features
  # @param :errors [#call, nil] a proc, accepting an error, which will be called with any errors which occur while determinating
  # @param :missing_feature [#call, nil] a proc, accepting a feature name, which will be called any time a feature is requested but isn't available
  def self.configure(retrieval:, errors: nil, missing_feature: nil)
    @error_logger = errors if errors.respond_to?(:call)
    @missing_feature_logger = missing_feature if missing_feature.respond_to?(:call)
    @instance = Control.new(retrieval: retrieval)
  end

  # @return [Determinator::Control] The currently active instance of determinator.
  # @raises [RuntimeError] If no Determinator instance is set up (with `.configure`)
  def self.instance
    raise "No singleton Determinator instance defined" unless @instance
    @instance
  end

  # Returns the feature with the given name as Determinator uses it. This is useful for
  # debugging issues with the retrieval mechanism which delivers features to Determinator.
  # @returns [Determinator::Feature,nil] The feature details Determinator would use for a determination right now.
  def self.feature_details(name)
    instance.retrieval.retrieve(name)
  end

  def self.notice_error(error)
    return unless @error_logger

    @error_logger.call(error)
  end

  def self.missing_feature(name)
    return unless @missing_feature_logger

    @missing_feature_logger.call(name)
  end
end
