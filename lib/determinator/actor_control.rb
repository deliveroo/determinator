module Determinator
  # A decorator to provide syntactic sugar for Determinator::Control.
  # Useful for contexts where the actor remains constant (eg. inside
  # the request cycle in a webapp)
  class ActorControl
    attr_reader :id, :guid, :default_constraints

    def initialize(controller, id: nil, guid: nil, default_constraints: {})
      @id = id
      @guid = guid
      @default_constraints = default_constraints
      @controller = controller
    end

    def which_variant(name, constraints: {})
      controller.which_variant(
        name,
        id: id,
        guid: guid,
        constraints: default_constraints.merge(constraints)
      )
    end

    def feature_flag_on?(name, constraints: {})
      controller.show_feature?(
        name,
        id: id,
        guid: guid,
        constraints: default_constraints.merge(constraints)
      )
    end

    def inspect
      "#<Determinator::ActorControl id=#{id.inspect} guid=#{guid.inspect}>"
    end

    private

    attr_reader :controller
  end
end
