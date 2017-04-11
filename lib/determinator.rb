require 'determinator/version'
require 'determinator/control'
require 'determinator/feature'
require 'determinator/target_group'
require 'determinator/retrieve/routemaster'

module Determinator
  def self.configure(update_using:)
    @instance = Control.new(retrieval: update_using)
  end

  def self.instance
    raise "No singleton Determinator instance defined" unless @instance
    @instance
  end
end
