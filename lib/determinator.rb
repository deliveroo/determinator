require 'determinator/version'
require 'determinator/control'
require 'determinator/feature'
require 'determinator/target_group'
require 'determinator/retrieve/routemaster'
require 'determinator/retrieve/null_retriever'

module Determinator
  # @param :retrieval [Determinator::Retrieve::Routemaster] A retrieval instance for Features
  # @param :errors [Proc, nil] a proc, accepting an error, which will be called with any errors which occur while determinating
  def self.configure(retrieval:, errors: nil)
    @error_logger = errors if errors.respond_to?(:call)
    @instance = Control.new(retrieval: retrieval)
  end

  def self.instance
    raise "No singleton Determinator instance defined" unless @instance
    @instance
  end

  def self.notice_error(error)
    return unless @error_logger

    @error_logger.call(error)
  end
end
