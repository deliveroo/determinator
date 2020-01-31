module Determinator
  module Tracking
    class Context
      attr_reader :request_id, :service, :resource

      def initialize(request_id: nil, service: nil, resource: nil)
        @request_id = request_id
        @service = service
        @resource = resource
      end
    end
  end
end
