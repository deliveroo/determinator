require 'faraday'

module Determinator
  module Retrieve
    # A class which loads features from Dynaconf server
    class Dynaconf
      # @param :host [String] The host for local Dynaconf server
      # @param :client [String] Faraday client instance, defaults to a new instance
      def initialize(host:, client: default_client)
        @host = host
        @client = client
      end

      def retrieve(feature_id)
        url = "http://#{@host}/scopes/florence-#{feature_id}/feature"

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
