module Determinator
  module Retrieve
    # Middleware which indexes features by their name, so we can look up a feature by name
    # and find the details (which are only accessible by ID)
    class RoutemasterIndexingMiddleware
      def initialize(app)
        @app = app
      end

      def call(env)
        content = JSON.parse(env.body)

        if content_describes_feature?(content)
          key = Routemaster.index_cache_key(content['name'])
          ::Routemaster::Config.cache_redis.set(key, content['id'])
        end

        @app.call(env)
      end

      private

      def content_describes_feature?(content)
        content['id'] && content['name'] && content['bucket_type']
      end
    end
  end
end
