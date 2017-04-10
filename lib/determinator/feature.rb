module Determinator
  # A model for an individual feature or experiment
  #
  # @attr_reader [nil,Hash<String,Integer>] variants The variants for this experiment, with the name of the variant as the key and the weight as the value. Will be nil for non-experiments.
  class Feature
    attr_reader :name, :identifier, :bucket_type, :variants, :target_groups

    BUCKET_TYPES = %i(id guid fallback)

    def initialize(name:, identifier:, bucket_type:, target_groups:, variants: {}, overrides: {})
      @name = name.to_s
      @identifier = identifier.to_s
      @variants = variants
      @target_groups = target_groups

      @bucket_type = bucket_type.to_sym
      raise ArgumentError, "Unknown bucket type: #{bucket_type}" unless BUCKET_TYPES.include?(@bucket_type)

      # To prevent confusion between actor id data types
      @overrides = Hash[overrides.map { |k, v| [k.to_s, v] }]
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

    def to_hash
      {
        'name'          => name,
        'seed'          => seed,
        'slice_type'    => slice_type,
        'variants'      => variants,
        'overrides'     => overrides,
        'target_groups' => target_groups.map(&:to_hash)
      }
    end

    def self.from_hash(hash)
      new(
        name:          hash['name'],
        seed:          hash['seed'],
        slice_type:    hash['slice_type'],
        variants:      hash['variants'],
        overrides:     hash['overrides'],
        target_groups: hash['target_groups'].map(&TargetGroup.method(:from_hash))
      )
    end

    def ==(other)
      to_hash == other.to_hash
    end

    def inspect
      "#<Feature #{name}>"
    end

    private

    attr_reader :overrides
  end
end
