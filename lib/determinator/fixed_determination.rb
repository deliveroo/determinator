module Determinator
  class FixedDetermination
    attr_reader :on, :variant, :constraints

    def initialize(on:, variant:, constraints: {})
      @on = on
      @variant = variant
      @constraints = constraints
    end

    def inspect
      "<on: #{on}, variant: #{variant}, constraints: #{constraints}"
    end

    def ==(other)
      return false unless other.is_a?(self.class)
      other.on == on && other.variant == variant && other.constraints == constraints
    end
  end
end
