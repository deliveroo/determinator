module Determinator
  # A decorator to provide syntactic sugar for Determinator::Control.
  # Useful for contexts where the actor remains constant (eg. inside
  # the request cycle in a webapp)
  class ActorControl
    attr_reader :id, :guid, :default_constraints

    def initialize(controller, id: nil, guid: nil, default_properties: {})
      @id = id
      @guid = guid
      @default_properties = default_properties
      @controller = controller
    end

    def which_variant(name, properties: {})
      controller.which_variant(
        name,
        id: id,
        guid: guid,
        properties: default_properties.merge(properties)
      )
    end

    def feature_flag_on?(name, properties: {})
      controller.feature_flag_on?(
        name,
        id: id,
        guid: guid,
        properties: default_properties.merge(properties)
      )
    end

    def inspect
      "#<Determinator::ActorControl id=#{id.inspect} guid=#{guid.inspect}>"
    end

    private

    attr_reader :controller
  end
end
