require 'faraday'

module Determinator
  module Retrieve

    class HttpRetriever
      def initialize(connection:)
        raise ArgumentError, "client must be a Faraday::Connection" unless connection.is_a?(Faraday::Connection)
        @connection = connection
      end

      def retrieve(name)
        before_hook
        response = @connection.get("/features/#{name}")
        after_hook(response.status)
        return Determinator::Serializers::JSON.load(response.body) if response.status == 200
        return MissingResponse.new if response.status == 404
      rescue => e
        Determinator.notice_error(e)
        after_hook(500)
        ErrorResponse.new
      end

      # Returns a feature name given a actor-tracking url. Used so we are able
      # to expire a cache using a feature name given an event url.
      #
      # Not intended to be generic, and makes no guarantees about support for
      # alternative url schemes.
      #
      # @param url [String] a actor tracking url
      # @return [String, nil] a feature name or nil
      def get_name(url)
        (url.match('features\/(.*)\z') || [])[1]
      end

      def before_retrieve(&block)
        @before_retrieve = block
      end

      def after_retrieve(&block)
        @after_retrieve = block
      end

      private

      def after_hook(args)
        return unless @after_retrieve
        @after_retrieve.call(args)
      end

      def before_hook
        return unless @before_retrieve
        @before_retrieve.call
      end
    end
  end
end
