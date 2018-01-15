require 'json'

module Determinator
  module Serializers
    module JSON
      class << self
        def dump(feature)
          raise NotImplementedError
        end

        def load(string_or_hash)
          obj = string_or_hash.is_a?(Hash) ? string_or_hash : ::JSON.parse(string_or_hash)

          Determinator::Feature.new(
            name:            obj['name'],
            identifier:      obj['identifier'],
            bucket_type:     obj['bucket_type'],
            active:          (obj['active'] === true),
            target_groups:   obj['target_groups'],
            variants:        obj['variants'].to_h,
            overrides:       obj['overrides'].to_h,
            winning_variant: obj['winning_variant'].to_s,
          )
        end
      end
    end
  end
end
