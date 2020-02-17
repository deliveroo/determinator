module Determinator
  module Tracking
    class Determination
      attr_reader :id, :guid, :feature_id, :determination

      def initialize(id:, guid:, feature_id:, determination:)
        @id = id
        @guid = guid
        @feature_id = feature_id
        @determination = determination
      end

      def ==(other)
        id == other.id && guid == other.guid && feature_id == other.feature_id && determination == other.determination
      end
    end
  end
end
