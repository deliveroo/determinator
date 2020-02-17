module Determinator
  module Tracking
    class Request
      attr_reader :type, :time, :error, :attributes, :determinations, :context

      def initialize(type:, time:, error:, attributes:, determinations:, context: nil)
        @type = type
        @time = time
        @error = error
        @attributes = attributes
        @determinations = determinations
        @context = context
      end

      def error?
        error
      end
    end
  end
end
