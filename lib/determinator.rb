require 'determinator/version'
require 'determinator/control'
require 'determinator/feature'
require 'determinator/target_group'
require 'determinator/retrieve/routemaster'
require 'determinator/retrieve/null_retriever'

module Determinator
  def self.configure(retrieval:)
    @instance = Control.new(retrieval: retrieval)
  end

  def self.instance
    raise "No singleton Determinator instance defined" unless @instance
    @instance
  end
end
