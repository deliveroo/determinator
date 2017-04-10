require 'digest/md5'
require 'determinator/actor_control'

module Determinator
  class Control
    def initialize(feature_store:)
      @feature_store = feature_store
    end

    # @return [ActorControl] A helper object removing the need to know id and guid everywhere
    def for_actor(id: nil, guid: nil, default_constraints: {})
      ActorControl.new(self, id: id, guid: guid, default_constraints: default_constraints)
    end

    # Determines whether a specific feature is on or off for the given actor
    #
    # @return [true,false] Whether the feature is on (true) or off (false) for this actor
    def show_feature?(name, id: nil, guid: nil, constraints: {})
      determinate(name, id: id, guid: guid, constraints: constraints) do |feature|
        !feature.experiment?
      end
    end

    # Determines what an actor should see for a specific experiment
    #
    # @return [false,String] Returns false, if the actor is not in this experiment, or otherwise the variant name.
    def which_variant(name, id: nil, guid: nil, constraints: {})
      determinate(name, id: id, guid: guid, constraints: constraints) do |feature|
        feature.experiment?
      end
    end

    private

    attr_reader :feature_store

    Indicators = Struct.new(:rollout, :variant)

    def determinate(name, id:, guid:, constraints:)
      feature = feature_store.feature(name)
      return false unless feature

      # Calling method can place constraints on the feature, eg. experiment only
      return false if block_given? && !yield(feature)

      # Overrides take precedence
      return feature.override_value_for(id) if feature.overridden_for?(id)

      target_group = choose_target_group(feature, constraints)
      # Given constraints have excluded this actor from this experiment
      return false unless target_group

      indicators = indicators_for(feature, id, guid)

      # Actor's indicator has excluded them from the feature
      return false if indicators.rollout >= target_group.rollout

      # Features don't need variant determination and, at this stage,
      # they have been rolled out to.
      return true unless feature.experiment?

      variant_for(feature, indicators.variant)
    end

    def choose_target_group(feature, constraints)
      feature.target_groups.select { |tg|
        tg.constraints.reduce(true) do |fit, (scope, *required)|
          present = [*constraints[scope]]
          fit && (required.flatten & present.flatten).any?
        end
      # Must choose target group deterministically, if more than one match
      }.sort_by { |tg| tg.rollout }.last
    end

    def indicators_for(feature, id, guid)
      # If we're slicing by guid then we never pay attention to id
      actor_identifier = case feature.bucket_type
                         when :id       then id
                         when :guid     then guid
                         when :fallback then id || guid
                         end
      # No identified means not enough info was given by the caller
      # to determine an outcome for this feature
      if actor_identifier.nil?
        raise ArgumentError, "Identifier for '#{feature.bucket_type}' type cannot be found from id: #{id}, guid: #{guid}"
      end

      # Cryptographic hash (will have random distribution)
      hash = Digest::MD5.new
      hash.update [feature.identifier, actor_identifier].map(&:to_s).join(',')

      # Use lowest 16 bits for rollout indicator
      # Use next 16 bits for variant indicator
      rollout, variant = hash.digest.unpack("nn")

      Indicators.new(rollout, variant)
    end

    def variant_for(feature, indicator)
      # Scale up the weights so the variants fit within the possible space for the variant indicator
      variant_weight_total = feature.variants.values.reduce(:+)
      scale_factor = 65_535 / variant_weight_total.to_f

      # Find the variant the indicator sits within
      previous_upper_bound = 0
      feature.variants.each do |name, weight|
        new_upper_bound = previous_upper_bound + scale_factor * weight
        return name if indicator <= new_upper_bound
        previous_upper_bound = new_upper_bound
      end

      raise ArgumentError, "A variant should have been found by this point, there is a bug in the code."
    end
  end
end
