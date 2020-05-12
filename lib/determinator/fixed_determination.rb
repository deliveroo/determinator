module Determinator
  class FixedDetermination
    attr_reader :active, :variant, :constraints

    def initialize(active:, variant:, constraints: {})
      @active = active
      @variant = variant
      @constraints = constraints
    end

    def inspect
      "<active: #{active}, variant: #{variant}, constraints: #{constraints}"
    end

    def ==(other)
      return false unless other.is_a?(self.class)
      other.active == active && other.variant == variant && other.constraints == constraints
    end
  end
end
