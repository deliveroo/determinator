require 'uri'
require 'routemaster/drain/caching'
require 'routemaster/responses/hateoas_response'
require 'determinator/retrieve/null_cache'

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

      def retrieve(feature_id)
        cached_feature_lookup(feature_id) do
          @actor_service.feature.show(feature_id)
        end
      rescue ::Routemaster::Errors::ResourceNotFound
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

      def self.index_cache_key(feature_name)
        "determinator_index:#{feature_name}"
      end

      def self.lookup_cache_key(feature_name)
        "determinator_cache:#{feature_name}"
      end

      private

      def cached_feature_lookup(feature_name)
        build_feature_from_api_response(
          @retrieval_cache.fetch(self.class.lookup_cache_key(feature_name)){ yield }
        )
      end

      def build_feature_from_api_response(obj)
        Feature.new(
          name:          obj.body.name,
          identifier:    obj.body.identifier,
          bucket_type:   obj.body.bucket_type,
          active:        obj.body.active,
          target_groups: target_groups_attribute(obj.body.target_groups),
          variants:      obj.body.variants.to_h,
          overrides:     overrides_attribute(obj.body.overrides),
          winning_variant: obj.body.winning_variant,
        )
      end

      def target_groups_attribute(target_groups)
        target_groups.map do |tg|
          TargetGroup.new(
            rollout: tg.rollout,
            constraints: constraints_attribute(tg.constraints)
          )
        end
      end

      def constraints_attribute(constraints)
        # TODO when FLO-3 closed: no need for legacy guard
        return legacy_constraints_attribute(constraints) unless constraints.respond_to?(:each_pair)
        constraints
      end

      def legacy_constraints_attribute(constraints)
        constraints.each_with_object({}) do |constraint, h|
          if h[constraint.scope]
            h[constraint.scope] = [*h[constraint.scope], constraint.identifier]
          else
            h[constraint.scope] = constraint.identifier
          end
        end
      end

      def overrides_attribute(overrides)
        # TODO when FLO-3 closed: no need for legacy guard
        return legacy_overrides_attribute(overrides) unless overrides.respond_to?(:each_pair)
        overrides
      end

      def legacy_overrides_attribute(overrides)
        overrides.each_with_object({}) do |override, h|
          h[override[:user_id]] = override[:variant]
        end
      end
    end
  end
end
