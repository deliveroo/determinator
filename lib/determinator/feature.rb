module Determinator
  # A model for an individual feature or experiment
  #
  # @attr_reader [nil,Hash<String,Integer>] variants The variants for this experiment, with the name of the variant as the key and the weight as the value. Will be nil for non-experiments.
  class Feature
    attr_reader :name, :seed, :slice_type, :variants, :target_groups

    SLICE_TYPES = %i(id guid fallback)

    def initialize(name:, seed:, slice_type:, target_groups:, variants: {}, overrides: {})
      @name = name.to_s
      @seed = seed.to_s
      @variants = variants
      @target_groups = target_groups

      @slice_type = slice_type.to_sym
      raise ArgumentError, "Unknown slice type: #{slice_type}" unless SLICE_TYPES.include?(@slice_type)

      # To prevent confusion between actor id data types
      @overrides = Hash[overrides.map { |k, v| [k.to_s, v] }]
    end

    # @return [true,false] Is this feature an experiment?
    def experiment?
      variants.any?
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

    private

    attr_reader :overrides
  end
end
