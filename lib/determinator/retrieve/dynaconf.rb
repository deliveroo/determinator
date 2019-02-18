require 'faraday'

module Determinator
  module Retrieve
    # A class which loads features from Dynaconf server
    class Dynaconf
      # @param :base [String] The protocol, host and port for local Dynaconf server
      # @param :service [String] The name of the service to be included in the User-Agent
      # @param :client [String] Faraday client instance, defaults to a new instance
      def initialize(base_url:, service_name:, client: default_client)
        raise ArgumentError, "client must be a Faraday::Connection" unless client.is_a?(Faraday::Connection)

        @base_url = base_url
        @service_name = service_name
        @client = client
      end

      def retrieve(feature_id)
        response = get(feature_id)
        Determinator::Serializers::JSON.load(response.body) if response.status == 200
      rescue => e
        Determinator.notice_error(e)
        nil
      end

      private

      def get(feature_id)
        url = "#{@base_url}/scopes/florence-#{feature_id}/feature"

        @client.get do |request|
          request.url(url)
          request['User-Agent'] = "Determinator v#{Determinator::VERSION} - #{@service_name}"
        end
      end

      def default_client
        Faraday.new
      end
    end
  end
end
