module Determinator
  module Tracking
    class Request
      attr_reader :start, :type, :endpoint, :time, :error, :attributes, :determinations, :context

      def initialize(start:, type:, endpoint:, time:, error:, attributes:, determinations:, context: nil)
        @start = start
        @type = type
        @time = time
        @error = error
        @attributes = attributes
        @determinations = determinations
        @endpoint = endpoint
        @context = context
      end

      def error?
        error
      end
    end
  end
end
