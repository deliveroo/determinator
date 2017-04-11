require 'uri'
require 'routemaster/drain/caching'
require 'routemaster/responses/hateoas_response'

module Determinator
  module Retrieve
    # A storage and retrieval engine for Determinator using routemaster-drain.
    #
    # To use this correctly you will need the following environment variables set to appropriate values
    # for your instance of Routemaster:
    #
    # ROUTEMASTER_DRAIN_TOKENS
    # ROUTEMASTER_DRAIN_REDIS
    # ROUTEMASTER_CACHE_REDIS
    # ROUTEMASTER_CACHE_AUTH
    # ROUTEMASTER_QUEUE_NAME
    # ROUTEMASTER_CALLBACK_URL
    class Routemaster
      attr_reader :routemaster_listener

      # @param :discovery_url [String] The bootstrap URL of the instance of Florence which defines Features.
      def initialize(discovery_url:)
        client = ::Routemaster::APIClient.new(
          response_class: ::Routemaster::Responses::HateoasResponse,
          middlewares: [FeatureIndexMiddleware]
        )
        @routemaster = client.discover(discovery_url)
        @routemaster_listener = ::Routemaster::Drain::Caching.new
      end

      def retrieve(feature_name)
        key = self.class.index_cache_key(feature_name)
        feature_id = ::Routemaster::Config.cache_redis.get(key)
        return unless feature_id

        obj = routemaster.feature.show(feature_id)
        attrs = obj.body.attributes

        Feature.new(
          name:          attrs.name,
          identifier:    attrs.identifier,
          bucket_type:   attrs.bucket_type,
          target_groups: attrs.target_groups.map { |tg|
            TargetGroup.new(
              rollout: tg.rollout,
              constraints: tg.constraints.to_hash
            )
          },
          variants:      attrs.variants.to_hash,
          overrides:     attrs.overrides.to_hash
        )
      rescue ::Routemaster::Errors::ResourceNotFound
        nil
      end

      # Returns the path component of the URL that Routemaster will send changes to.
      #
      # This is useful for adding the `routemaster_listener` rack application to your application's routes file
      # if not using #configure_rails_router.
      #
      #     map(your_instance_of_determinator.retrieval.routemaster_callback_path) do
      #       your_instance_of_determinator.retrieval.routemaster_listener
      #     end
      #
      # @return [String] The path of the URL Routemaster will send event notifications to.
      def routemaster_callback_path
        URI.parse(ENV['ROUTEMASTER_CALLBACK_URL']).path
      end

      # Automatically configures the rails router to listen for Features with routemaster
      #
      # @param route_mapper [ActionDispatch::Routing::Mapper] The rails mapper, 'self' within the `routes.draw` block
      def configure_rails_router(route_mapper)
        route_mapper.mount routemaster_listener, at: routemaster_callback_path
      end

      def self.index_cache_key(feature_name)
        "determinator_index:#{feature_name}"
      end

      private

      attr_reader :routemaster

      class FeatureIndexMiddleware
        def initialize(app)
          @app = app
          @redis = ::Routemaster::Config.cache_redis
        end

        def call(env)
          feature = JSON.parse(env.body)
          key = Routemaster.index_cache_key(feature['attributes']['name'])
          @redis.set(key, feature['id'])
          @app.call(env)
        end
      end
    end
  end
end
