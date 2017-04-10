module Determinator
  class TargetGroup
    attr_reader :rollout, :constraints

    def initialize(rollout:, constraints: {})
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

    def inspect
      pc = (rollout_percent * 100).to_f.round(1)
      "<#{pc}% of those matching: #{constraints}>"
    end

    def to_hash
      {
        'rollout'     => rollout,
        'constraints' => constraints
      }
    end

    def self.from_hash(hash)
      new(
        rollout:     hash['rollout'],
        constraints: hash['constraints']
      )
    end
  end
end
