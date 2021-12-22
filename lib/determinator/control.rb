require 'digest/md5'
require 'determinator/actor_control'
require 'semantic'
require 'securerandom'

module Determinator
  class Control
    attr_reader :retrieval, :explainer

    def initialize(retrieval:)
      @retrieval = retrieval
      @explainer = Determinator::Explainer.new
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
    # @param :feature [Feature] The feature to use instead of retrieving one
    # @raise [ArgumentError] When the arguments given to this method aren't ever going to produce a useful response
    # @return [true,false] Whether the feature is on (true) or off (false) for this actor
    def feature_flag_on?(name, id: nil, guid: nil, properties: {}, feature: nil)
      determinate_and_notice(name, id: id, guid: guid, properties: properties, feature: feature) do |feature|
        feature.feature_flag?
      end
    end

    # Determines what an actor should see for a specific experiment
    #
    # @param name [#to_s] The name of the experiment being checked
    # @param :id [#to_s] The id of the actor being determinated for
    # @param :guid [#to_s] The Anonymous id of the actor being determinated for
    # @param :properties [Hash<Symbol,String>] The properties of this actor which will be used for including this actor or not
    # @param :feature [Feature] The feature to use instead of retrieving one
    # @raise [ArgumentError] When the arguments given to this method aren't ever going to produce a useful response
    # @return [false,String] Returns false, if the actor is not in this experiment, or otherwise the variant name.
    def which_variant(name, id: nil, guid: nil, properties: {}, feature: nil)
      determinate_and_notice(name, id: id, guid: guid, properties: properties, feature: feature) do |feature|
        feature.experiment?
      end
    end

    def explain_determination(name, id: nil, guid: nil, properties: {})
      explainer.explain do
        determinate_and_notice(name, id: id, guid: guid, properties: properties)
      end
    end

    # Uses the retrieval (and a cache if set on the Determinator config) to fetch a feature definition.
    #
    # @param name [#to_s] The name of the experiment being checked
    # @return [Feature, MissingResponse] Returns the Feature object, or MissingResponse if the feature is not found.
    def retrieve(name)
      Determinator.with_retrieval_cache(name) { retrieval.retrieve(name) }
    end

    def inspect
      '#<Determinator::Control>'
    end

    private

    Indicators = Struct.new(:rollout, :variant)

    def determinate_and_notice(name, id:, guid:, properties:, feature: nil)
      feature ||= retrieve(name)

      if feature.nil? || feature.is_a?(ErrorResponse) || feature.is_a?(MissingResponse)
        Determinator.notice_missing_feature(name)
        return false
      end

      determinate(feature, id: id, guid: guid, properties: properties).tap do |determination|
        Determinator.notice_determination(id, guid, feature, determination)
      end
    end

    def determinate(feature, id:, guid:, properties:)
      # Calling method can place constraints on the feature, eg. experiment only
      return false if block_given? && !yield(feature)

      explainer.log(:start, { feature: feature } )

      # Inactive features are always, always off
      return false unless feature_active?(feature)

      return override_value(feature, id) if feature_overridden?(feature, id)

      fixed_determination = choose_fixed_determination(feature, properties)
      # Given constraints have specified that this actor's determination should be fixed
      if fixed_determination
        return explainer.log(:chosen_fixed_determination, { fixed_determination: fixed_determination }) {
          fixed_determination_value(feature, fixed_determination)
        }
      end

      target_group = choose_target_group(feature, properties)
      # Given constraints have excluded this actor from this experiment
      return false unless target_group

      indicators = indicators_for(feature, actor_identifier(feature, id, guid))
      # This actor isn't described in enough detail to form indicators
      return false unless indicators

      # Actor's indicator has excluded them from the feature
      return false if excluded_from_rollout?(indicators, target_group)

      # Features don't need variant determination and, at this stage,
      # they have been rolled out to.
      # require_variant_determination?
      return true unless require_variant_determination?(feature)



      explainer.log(:chosen_variant) {
        variant_for(feature, indicators.variant)
      }
    rescue ArgumentError
      raise

    rescue => e
      Determinator.notice_error(e)
      false
    end

    def feature_active?(feature)
      explainer.log(:feature_active) {
        feature.active?
      }
    end

    def feature_overridden?(feature, id)
      explainer.log(:feature_overridden_for) {
        feature.overridden_for?(id)
      }
    end

    def override_value(feature, id)
      explainer.log(:override_value, { id: id }) {
        feature.override_value_for(id)
      }
    end

    def excluded_from_rollout?(indicators, target_group)
      explainer.log(:excluded_from_rollout, { target_group: target_group } ) {
        indicators.rollout >= target_group.rollout
      }
    end

    def require_variant_determination?(feature)
      explainer.log(:require_variant_determination) {
        feature.experiment?
      }
    end

    def fixed_determination_value(feature, fixed_determination)
      return false unless fixed_determination.feature_on
      return true unless feature.experiment?
      return fixed_determination.variant
    end

    def choose_fixed_determination(feature, properties)
      return unless feature.fixed_determinations

      # Keys and values must be strings
      normalised_properties = normalise_properties(properties)

      feature.fixed_determinations.find do |fd|
        explainer.log(:possible_match_fixed_determination, { fixed_determination: fd }) {
          check_fixed_determination(fd, normalised_properties)
        }
      end
    end

    def check_fixed_determination(fixed_determination, properties)
      explainer.log(:check_fixed_determination, { fixed_determination: fixed_determination })

      matches_constraints(properties, fixed_determination.constraints)
    end

    def choose_target_group(feature, properties)
      # Keys and values must be strings
      normalised_properties = normalise_properties(properties)

      # Must choose target group deterministically, if more than one match
      explainer.log(:chosen_target_group) {
        filtered_target_groups(feature, normalised_properties).sort_by { |tg| tg.rollout }.last
      }
    end

    def filtered_target_groups(feature, properties)
      feature.target_groups.select do |tg|
        explainer.log(:possible_match_target_group, { target_group: tg }) {
          check_target_group(tg, properties)
        }
      end
    end

    def check_target_group(target_group, properties)
      explainer.log(:check_target_group, { target_group: target_group })

      return false unless target_group.rollout.between?(1, 65_536)

      matches_constraints(properties, target_group.constraints)
    end

    def matches_constraints(normalised_properties, constraints)
      unless constraints.all?{ |k, v| k.is_a?(String) && v.all?{ |vv| vv.is_a?(String) } }
        raise "Constraints must by arrays of strings"
      end
      constraints.reduce(true) do |fit, (scope, *required)|
        present = [*normalised_properties[scope]]
        fit && matches_requirements?(scope, required, present)
      end
    end

    def matches_requirements?(scope, required, present)
      case scope
        when "app_version" then has_any_app_version?(required, present)
        when "request.app_version" then has_any_app_version?(required, present)
        else has_any?(required, present)
      end
    end

    def has_any?(required, present)
      (required.flatten & present.flatten).any?
    end

    def has_any_app_version?(required, present)
      invalid_properties = present.flatten.select do |v|
        !v.match?(Semantic::Version::SemVerRegexp)
      end
      invalid_groups = required.flatten.select do |v|
        !v.match?(/\d/)
      end

      return false if (invalid_properties + invalid_groups).any?

      present.flatten.any? do |g|
        given_version = Semantic::Version.new(g)
        required.flatten.all? do |n|
          given_version.satisfies?(n)
        end
      end
    end

    def actor_identifier(feature, id, guid)
      case feature.bucket_type
      when :id
        explainer.log(:missing_identifier, { identifier_type: 'ID' }) unless id
        id
      when :guid
        return guid if guid.to_s != ''

        explainer.log(:missing_identifier, { identifier_type: 'GUID' })
        return
      when :fallback
        identifier = (id || guid).to_s
        return identifier if identifier != ''

        raise ArgumentError, 'An ID or GUID must always be given for Fallback bucketed features'
      when :single
        SecureRandom.hex(64)
      else
        explainer.log(:unknown_bucket, { feature: feature } )
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

    private

    def normalise_properties(properties)
      properties.each_with_object({}) do |(name, values), hash|
        hash[name.to_s] = [*values].map(&:to_s)
      end
    end
  end
end
