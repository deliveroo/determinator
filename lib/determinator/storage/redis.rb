require 'json'

module Determinator
  module Storage
    class Redis
      def initialize(redis, prefix: 'determinator')
        @redis                = redis
        @prefix               = prefix
        @origin_last_modified = Time.at(0)
      end

      # @return [Array<Determinator::Feature>] All stored features
      def get_all
        features = []

        cursor = "0"
        loop do
          cursor, keys = redis.scan(cursor, match: feature_key('*'))

          redis.mget(keys).each do |data|
            features << deserialize(data)
          end

          break if cursor == "0"
        end

        features
      end

      # @param feature_name [String] The name of the desired feature
      # @return [Determinator::Feature,nil] The specified feature or nil, if one by that name doesn't exist
      def get(feature_name)
        deserialize(
          redis.get(
            feature_key(feature_name)
          )
        )
      end

      # Puts a feature into storage
      #
      # @param feature [Determinator::Feature] The feature being stored
      # @param origin_last_modified [Time] The time of the last modified feature, as defined by the originating service
      # @return [nil]
      def put(feature, origin_last_modified)
        redis.set(
          feature_key(feature.name),
          serialize(feature)
        )
        update_most_recent_feature_seen_timestamp(origin_last_modified)
        nil
      end

      # @return [Time,nil] The last time features were received from the originating service, as declared by it.
      def origin_last_modified
        @origin_last_modified ||= Time.at(
          redis.get(most_recent_feature_seen_key).to_f
        )
      end

      private

      attr_reader :redis

      def update_most_recent_feature_seen_timestamp(time)
        return if time <= origin_last_modified
        redis.set(
          most_recent_feature_seen_key,
          time.to_f
        )
        @origin_last_modified = time
        nil
      end

      def most_recent_feature_seen_key
        [@prefix, 'most_recent_feature_seen'].join(':')
      end

      def feature_key(feature_name)
        [@prefix, 'features', feature_name].join(':')
      end

      def serialize(feature)
        JSON.generate(feature.to_hash)
      end

      def deserialize(data)
        return if data.nil?
        Determinator::Feature.from_hash(JSON.parse(data))
      end
    end
  end
end
