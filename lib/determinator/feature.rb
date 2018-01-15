module Determinator
  # A model for an individual feature or experiment
  #
  # @attr_reader [nil,Hash<String,Integer>] variants The variants for this experiment, with the name of the variant as the key and the weight as the value. Will be nil for non-experiments.
  class Feature
    attr_reader :name, :identifier, :bucket_type, :variants, :target_groups, :active, :winning_variant

    def initialize(name:, identifier:, bucket_type:, target_groups:, variants: {}, overrides: {}, active: false, winning_variant: nil)
      @name = name.to_s
      @identifier = (identifier || name).to_s
      @variants = variants
      @target_groups = parse_target_groups(target_groups)
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

    private

    attr_reader :overrides

    def parse_target_groups(target_groups)
      target_groups.map(&method(:parse_target_group)).compact
    end

    def parse_target_group(target_group)
      return target_group if target_group.is_a? TargetGroup

      constraints = target_group['constraints'].to_h

      TargetGroup.new(
        rollout: target_group['rollout'].to_i,
        constraints: constraints.each_with_object({}) do |(key, value), hash|
          hash[key.to_s] = [*value].map(&:to_s)
        end
      )

    # Invalid target groups are ignored
    rescue
      nil
    end
  end
end
