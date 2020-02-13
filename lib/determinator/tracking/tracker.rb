require 'determinator/tracking/determination'
require 'determinator/tracking/request'

module Determinator
  module Tracking
    class Tracker
      attr_reader :type, :determinations

      def initialize(type)
        @determinations = []
        @type = type
        @start = now
      end

      def track(id, guid, feature, determination)
        determinations << Determinator::Tracking::Determination.new(
          id: id,
          guid: guid,
          feature_id: feature.identifier,
          determination: determination
        )
      end

      def finish!(error:, **attributes)
        request_time = now - @start
        Determinator::Tracking::Request.new(
          type: type,
          time: request_time,
          error: error,
          attributes: attributes,
          determinations: determinations,
          context: Determinator::Tracking.context
        )
      end

      private

      def now
        Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end
    end
  end
end
