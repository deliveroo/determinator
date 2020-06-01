module Determinator
  class TargetGroup
    attr_reader :name, :rollout, :constraints

    def initialize(name: '', rollout:, constraints: {})
      @name = name
      @rollout = rollout
      @constraints = constraints
    end

    def rollout_percent
      # Rollout is out of 65536 because the highest rollout indicator
      # (which is a 16 bit integer) can be is 65,535. 100% rollout
      # needs to include the highest indicator, and 0% needs to not include
      # the lowest indicator.
      Rational(rollout, 65_536)
    end

    def percentage
      (rollout_percent * 100).to_f.round(1)
    end

    def inspect
      "<TG name:'#{name}': #{percentage}% of those matching: #{constraints}>"
    end

    def ==(other)
      return false unless other.is_a?(self.class)
      other.name == name && other.rollout == rollout && other.constraints == constraints
    end
  end
end
