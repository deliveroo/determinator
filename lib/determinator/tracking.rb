require 'determinator/tracking/tracker'

module Determinator
  module Tracking
    class << self
      def instance
        Thread.current[:determinator_tracker]
      end

      def start!(type)
        Thread.current[:determinator_tracker] = Tracker.new(type)
      end

      def finish!(error:, **attributes)
        return false unless started?
        request = instance.finish!(error: error, **attributes)
        clear!
        report(request)
        request
      end

      def clear!
        Thread.current[:determinator_tracker] = nil
      end

      def started?
        !!instance
      end

      def track(id, guid, feature, determination)
        return false unless started?
        instance.track(id, guid, feature, determination)
      end

      def on_request(&block)
        @on_request = block
      end

      def clear_on_request!
        @on_request
      end

      def report(request)
        return unless @on_request
        @on_request.call(request)
      end
    end
  end
end
