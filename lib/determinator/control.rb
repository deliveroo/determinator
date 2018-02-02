require 'digest/md5'
require 'determinator/actor_control'

module Determinator
  class Control
    attr_reader :retrieval

    def initialize(retrieval:)
      @retrieval = retrieval
    end

    # Creates a new determinator instance which assumes the actor id, guid and properties given
    # are always specified. This is useful for within a before filter in a webserver, for example,
    # so that the determinator instance made available has the logged-in user's credentials prefilled.
    #
    # @param :id [#to_s] The ID of the actor being specified
    # @param :guid [#to_s] The Anonymous ID of the actor being specified
    # @param :default_properties [Hash<Symbol,String>] The default properties for the determinator being created
    # @return [ActorControl] A helper object removing the need to know id and guid everywhere
    def for_actor(id: nil, guid: nil, default_properties: {})
      ActorControl.new(self, id: id, guid: guid, default_properties: default_properties)
    end

    # Determines whether a specific feature is on or off for the given actor
    #
    # @param name [#to_s] The name of the feature flag being checked
    # @param :id [#to_s] The id of the actor being determinated for
    # @param :guid [#to_s] The Anonymous id of the actor being determinated for
    # @param :properties [Hash<Symbol,String>] The properties of this actor which will be used for including this actor or not
    # @raise [ArgumentError] When the arguments given to this method aren't ever going to produce a useful response
    # @return [true,false] Whether the feature is on (true) or off (false) for this actor
    def feature_flag_on?(name, id: nil, guid: nil, properties: {})
      determinate_and_notice(name, id: id, guid: guid, properties: properties) do |feature|
        feature.feature_flag?
      end
    end

    # Determines what an actor should see for a specific experiment
    #
    # @param name [#to_s] The name of the experiment being checked
    # @param :id [#to_s] The id of the actor being determinated for
    # @param :guid [#to_s] The Anonymous id of the actor being determinated for
    # @param :properties [Hash<Symbol,String>] The properties of this actor which will be used for including this actor or not
    # @raise [ArgumentError] When the arguments given to this method aren't ever going to produce a useful response
    # @return [false,String] Returns false, if the actor is not in this experiment, or otherwise the variant name.
    def which_variant(name, id: nil, guid: nil, properties: {})
      determinate_and_notice(name, id: id, guid: guid, properties: properties) do |feature|
        feature.experiment?
      end
    end

    def inspect
      '#<Determinator::Control>'
    end

    private

    Indicators = Struct.new(:rollout, :variant)

    def determinate_and_notice(name, id:, guid:, properties:)
      feature = Determinator.with_retrieval_cache(name) { retrieval.retrieve(name) }

      determinate(feature, id: id, guid: guid, properties: properties).tap do |determination|
        Determinator.notice_determination(id, guid, feature, determination)
      end
    end

    def determinate(feature, id:, guid:, properties:)
      if feature.nil?
        Determinator.notice_missing_feature(feature.name)
        return false
      end

      # Calling method can place constraints on the feature, eg. experiment only
      return false if block_given? && !yield(feature)

      # Inactive features are always, always off
      return false unless feature.active?

      return feature.override_value_for(id) if feature.overridden_for?(id)

      target_group = choose_target_group(feature, properties)
      # Given constraints have excluded this actor from this experiment
      return false unless target_group

      indicators = indicators_for(feature, actor_identifier(feature, id, guid))
      # This actor isn't described in enough detail to form indicators
      return false unless indicators

      # Actor's indicator has excluded them from the feature
      return false if indicators.rollout >= target_group.rollout

      # Features don't need variant determination and, at this stage,
      # they have been rolled out to.
      return true unless feature.experiment?

      variant_for(feature, indicators.variant)

    rescue ArgumentError
      raise

    rescue => e
      Determinator.notice_error(e)
      false
    end

    def choose_target_group(feature, properties)
      # Keys and values must be strings
      normalised_properties = properties.each_with_object({}) do |(name, values), hash|
        hash[name.to_s] = [*values].map(&:to_s)
      end

      feature.target_groups.select { |tg|
        next false unless tg.rollout.between?(1, 65_536)

        tg.constraints.reduce(true) do |fit, (scope, *required)|
          present = [*normalised_properties[scope]]
          fit && (required.flatten & present.flatten).any?
        end
      # Must choose target group deterministically, if more than one match
      }.sort_by { |tg| tg.rollout }.last
    end

    def actor_identifier(feature, id, guid)
      case feature.bucket_type
      when :id
        id
      when :guid
        return guid if guid.to_s != ''

        raise ArgumentError, 'A GUID must always be given for GUID bucketed features'
      when :fallback
        identifier = (id || guid).to_s
        return identifier if identifier != ''

        raise ArgumentError, 'An ID or GUID must always be given for Fallback bucketed features'
      when :single
        'all'
      else
        Determinator.notice_error "Cannot process the '#{feature.bucket_type}' bucket type found in #{feature.name}"
      end
    end

    def indicators_for(feature, actor_identifier)
      # No identified means not enough info was given by the caller
      # to determine an outcome for this feature
      return unless actor_identifier

      # Cryptographic hash (will have random distribution)
      hash = Digest::MD5.new
      hash.update [feature.identifier, actor_identifier].map(&:to_s).join(',')

      # Use lowest 16 bits for rollout indicator
      # Use next 16 bits for variant indicator
      rollout, variant = hash.digest.unpack("nn")

      Indicators.new(rollout, variant)
    end

    def variant_for(feature, indicator)
      return feature.winning_variant if feature.winning_variant

      # Scale up the weights so the variants fit within the possible space for the variant indicator
      variant_weight_total = feature.variants.values.reduce(:+)
      scale_factor = 65_535 / variant_weight_total.to_f

      sorted_variants = feature.variants.keys.sort
      # Find the variant the indicator sits within
      upper_bound = 0
      sorted_variants.each do |variant_name|
        upper_bound = upper_bound + scale_factor * feature.variants[variant_name]
        return variant_name if indicator <= upper_bound
      end

      raise ArgumentError, "A variant should have been found by this point, there is a bug in the code."
    end
  end
end
