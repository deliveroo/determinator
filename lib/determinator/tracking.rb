require 'determinator/tracking/tracker'
require 'determinator/tracking/context'

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

      def report(request)
        return unless @on_request
        @on_request.call(request)
      end

      def get_context(&block)
        @get_context = block
      end

      def context
        return unless @get_context
        @get_context.call
      rescue
        nil
      end

      def clear_hooks!
        @on_request = nil
        @get_context = nil
      end
    end
  end
end
