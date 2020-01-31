module Determinator
  module Tracking
    class Context
      attr_reader :request_id, :service, :resource

      def initialize(request_id: nil, service: nil, resource: nil, type: nil, meta: {})
        @request_id = request_id
        @service = service
        @resource = resource
        @type = type
        @meta = meta
      end
    end
  end
end
