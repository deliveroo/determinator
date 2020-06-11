module Determinator
  # A model for an individual feature or experiment
  #
  # @attr_reader [nil,Hash<String,Integer>] variants The variants for this experiment, with the name of the variant as the key and the weight as the value. Will be nil for non-experiments.
  class Feature
    attr_reader :name, :identifier, :bucket_type, :variants, :target_groups, :fixed_determinations, :active, :winning_variant

    def initialize(name:, identifier:, bucket_type:, target_groups:, fixed_determinations: [], variants: {}, overrides: {}, active: false, winning_variant: nil)
      @name = name.to_s
      @identifier = identifier.to_s
      @variants = variants
      @target_groups = parse_target_groups(target_groups)
      @fixed_determinations = parse_fixed_determinations(fixed_determinations)
      @winning_variant = parse_outcome(winning_variant, allow_exclusion: false)
      @active = active
      @bucket_type = bucket_type.to_sym

      # To prevent confusion between actor id data types
      @overrides = overrides.each_with_object({}) do |(identifier, outcome), hash|
        parsed = parse_outcome(outcome, allow_exclusion: true)
        hash[identifier.to_s] = parsed unless parsed.nil?
      end
    end

    def active?
      !!active
    end

    # @return [true,false] Is this feature an experiment?
    def experiment?
      variants.any?
    end

    # @return [true,false] Is this feature a feature flag?
    def feature_flag?
      variants.empty?
    end

    # Is this feature overridden for the given actor id?
    #
    # @return [true,false] Whether this feature is overridden for this actor
    def overridden_for?(id)
      overrides.has_key?(id.to_s)
    end

    def override_value_for(id)
      overrides[id.to_s]
    end

    # Validates the given outcome for this feature.
    def parse_outcome(outcome, allow_exclusion:)
      valid_outcomes = experiment? ? variants.keys : [true]
      valid_outcomes << false if allow_exclusion
      valid_outcomes.include?(outcome) ? outcome : nil
    end

    def ==(other)
      Marshal.dump(self) == Marshal.dump(other)
    end

    def to_explain_params
      { name: name, identifier: identifier, bucket_type: bucket_type }
    end

    private

    attr_reader :overrides

    def parse_target_groups(target_groups)
      target_groups.map(&method(:parse_target_group)).compact
    end

    def parse_target_group(target_group)
      return target_group if target_group.is_a? TargetGroup

      constraints = target_group['constraints'].to_h

      TargetGroup.new(
        name: target_group['name'],
        rollout: target_group['rollout'].to_i,
        constraints: parse_constraints(constraints)
      )

    # Invalid target groups are ignored
    rescue
      nil
    end

    def parse_fixed_determinations(fixed_determinations)
      fixed_determinations.map(&method(:parse_fixed_determination)).compact
    end

    def parse_fixed_determination(fixed_determination)
      return fixed_determination if fixed_determination.is_a? FixedDetermination

      variant = fixed_determination['variant']
      return nil if variant && !variants.keys.include?(variant)

      # if a variant is present the fixed determination should always be on
      return nil if variant && !fixed_determination['feature_on']

      constraints = fixed_determination['constraints'].to_h

      FixedDetermination.new(
        name: fixed_determination['name'],
        feature_on: fixed_determination['feature_on'],
        variant: variant,
        constraints: parse_constraints(constraints)
      )
    # Invalid fixed determinations are ignored
    rescue
      nil
    end

    def parse_constraints(constraints)
      constraints.each_with_object({}) do |(key, value), hash|
        hash[key.to_s] = [*value].map(&:to_s)
      end
    end
  end
end
