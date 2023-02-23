module Determinator
  # A decorator to provide syntactic sugar for Determinator::Control.
  # Useful for contexts where the actor remains constant (eg. inside
  # the request cycle in a webapp)
  class ActorControl
    attr_reader :id, :guid, :default_properties

    # @see Determinator::Control#for_actor
    def initialize(controller, id: nil, guid: nil, default_properties: {})
      @id = id
      @guid = guid
      @default_properties = default_properties
      @controller = controller
    end

    # @see Determinator::Control#which_variant
    def which_variant(name, properties: {}, feature: nil)
      controller.which_variant(
        name,
        id: id,
        guid: guid,
        properties: default_properties.merge(properties),
        feature: feature
      )
    end

    # @see Determinator::Control#feature_flag_on?
    def feature_flag_on?(name, properties: {}, feature: nil)
      controller.feature_flag_on?(
        name,
        id: id,
        guid: guid,
        properties: default_properties.merge(properties),
        feature: feature
      )
    end

    def inspect
      "#<Determinator::ActorControl id=#{id.inspect} guid=#{guid.inspect}>"
    end

    private

    attr_reader :controller
  end
end
