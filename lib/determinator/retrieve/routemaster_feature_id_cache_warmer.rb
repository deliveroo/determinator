module Determinator
  module Retrieve
    class RoutemasterFeatureIdCacheWarmer
      def initialize(payload)
        @payload = payload
      end

      def call
        response = client.get(@payload['url']).body
        if valid_feature_response?(response)
          key = Routemaster.index_cache_key(response['name'])
          ::Routemaster::Config.cache_redis.set(key, response['id'])
        end
      end

      private

      def client
        @client ||= ::Routemaster::APIClient.new(
          response_class: ::Routemaster::Responses::HateoasResponse
        )
      end

      def valid_feature_response?(response)
        response['id'] && response['name'] && response['bucket_type']
      end
    end
  end
end
