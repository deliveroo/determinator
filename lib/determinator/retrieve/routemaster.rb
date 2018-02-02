require 'uri'
require 'routemaster/drain/caching'
require 'routemaster/responses/hateoas_response'
require 'determinator/retrieve/null_cache'
require 'determinator/serializers/json'

module Determinator
  module Retrieve
    # A storage and retrieval engine for Determinator using routemaster-drain.
    #
    # To use this correctly you will need the following environment variables set to appropriate values
    # for your instance of Routemaster:
    #
    # ROUTEMASTER_CACHE_REDIS
    # ROUTEMASTER_CACHE_AUTH
    class Routemaster
      attr_reader :routemaster_app

      CALLBACK_PATH = (URI.parse(ENV['ROUTEMASTER_CALLBACK_URL']).path rescue '/events').freeze

      # @param :discovery_url [String] The bootstrap URL of the instance of Florence which defines Features.
      def initialize(discovery_url:, retrieval_cache: NullCache.new)
        client = ::Routemaster::APIClient.new(
          response_class: ::Routemaster::Responses::HateoasResponse
        )
        @retrieval_cache = retrieval_cache
        @actor_service = client.discover(discovery_url)

      end

      # Retrieves and processes the feature that goes by the given name on this retrieval mechanism.
      # @return [Determinator::Feature,nil] The details of the specified feature
      def retrieve(name)
        cached_feature_lookup(name) do
          @actor_service.feature.show(name)
        end
      rescue ::Routemaster::Errors::ResourceNotFound
        # Don't be noisy
        nil
      rescue => e
        Determinator.notice_error(e)
        nil
      end

      # Automatically configures the rails router to listen for Features with routemaster
      #
      # @param route_mapper [ActionDispatch::Routing::Mapper] The rails mapper, 'self' within the `routes.draw` block
      def configure_rails_router(route_mapper)
        route_mapper.mount routemaster_app, at: CALLBACK_PATH
      end

      def routemaster_app
        @routemaster_app ||= ::Routemaster::Drain::Caching.new
      end

      def self.lookup_cache_key(feature_name)
        "determinator_cache:#{feature_name}"
      end

      private

      def cached_feature_lookup(feature_name)
        obj = @retrieval_cache.fetch(self.class.lookup_cache_key(feature_name)){ yield }
        Determinator::Serializers::JSON.load(obj.body.to_hash)
      end
    end
  end
end
