require 'uri'
require 'routemaster/drain/caching'
require 'routemaster/responses/hateoas_response'
require 'determinator/retrieve/feature_id_cache_warmer'

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
      attr_reader :routemaster_app

      CALLBACK_PATH = (URI.parse(ENV['ROUTEMASTER_CALLBACK_URL']).path rescue '/events').freeze

      # @param :discovery_url [String] The bootstrap URL of the instance of Florence which defines Features.
      def initialize(discovery_url:)
        client = ::Routemaster::APIClient.new(
          response_class: ::Routemaster::Responses::HateoasResponse
        )
        @routemaster = client.discover(discovery_url)
        @routemaster_app = ::Routemaster::Drain::Caching.new(
          siphon_events: { 'features' => FeatureIdCacheWarmer }
        )
      end

      def retrieve(feature_name)
        key = self.class.index_cache_key(feature_name)
        feature_id = ::Routemaster::Config.cache_redis.get(key)
        return unless feature_id

        obj = @routemaster.feature.show(feature_id)

        Feature.new(
          name:          obj.body.name,
          identifier:    obj.body.identifier,
          bucket_type:   obj.body.bucket_type,
          target_groups: obj.body.target_groups.map { |tg|
            TargetGroup.new(
              rollout: tg.rollout,
              constraints: tg.constraints.to_h
            )
          },
          variants:      obj.body.variants.to_h,
          overrides:     obj.body.overrides.to_h
        )
      rescue ::Routemaster::Errors::ResourceNotFound
        nil
      end

      # Automatically configures the rails router to listen for Features with routemaster
      #
      # @param route_mapper [ActionDispatch::Routing::Mapper] The rails mapper, 'self' within the `routes.draw` block
      def configure_rails_router(route_mapper)
        route_mapper.mount routemaster_app, at: CALLBACK_PATH
      end

      def self.index_cache_key(feature_name)
        "determinator_index:#{feature_name}"
      end
    end
  end
end
