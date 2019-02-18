require 'faraday'

module Determinator
  module Retrieve
    # A class which loads features from Dynaconf server
    class Dynaconf
      # @param :base [String] The protocol, host and port for local Dynaconf server
      # @param :client [String] Faraday client instance, defaults to a new instance
      def initialize(base_url:, client: default_client)
        @base_url = base_url
        @client = client
      end

      def retrieve(feature_id)
        url = "#{@base_url}/scopes/florence-#{feature_id}/feature"

        payload = @client.get(url).body
        Determinator::Serializers::JSON.load(payload)
      rescue => e
        Determinator.notice_error(e)
        nil
      end

      private

      def default_client
        Faraday.new
      end
    end
  end
end
