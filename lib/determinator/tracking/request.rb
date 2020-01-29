module Determinator
  module Tracking
    class Request
      attr_reader :type, :time, :error, :attributes, :determinations

      def initialize(type:, time:, error:, attributes:, determinations:)
        @type = type
        @time = time
        @error = error
        @attributes = attributes
        @determinations = determinations
      end

      def error?
        error
      end
    end
  end
end
