require 'uri'
require 'routemaster/drain/caching'
require 'routemaster/responses/hateoas_response'
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
      def initialize(discovery_url:)
        client = ::Routemaster::APIClient.new(
          response_class: ::Routemaster::Responses::HateoasResponse
        )
        @actor_service = client.discover(discovery_url)
      end

      # Retrieves and processes the feature that goes by the given name on this retrieval mechanism.
      # @return [Determinator::Feature,nil] The details of the specified feature
      def retrieve(name)
        obj = @actor_service.feature.show(name)
        Determinator::Serializers::JSON.load(obj.body.to_hash)
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
    end
  end
end
