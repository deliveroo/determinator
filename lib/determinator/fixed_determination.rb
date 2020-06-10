module Determinator
  class FixedDetermination
    attr_reader :name, :feature_on, :variant, :constraints

    def initialize(feature_on:, variant:, name: '', constraints: {})
      @name = name
      @feature_on = feature_on
      @variant = variant
      @constraints = constraints
    end

    def inspect
      "<feature_on: #{feature_on}, variant: #{variant}, constraints: #{constraints}"
    end

    def to_explain_params
      { name: name }
    end

    def ==(other)
      return false unless other.is_a?(self.class)
      other.feature_on == feature_on && other.variant == variant && other.constraints == constraints
    end
  end
end
