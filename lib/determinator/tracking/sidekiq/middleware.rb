require 'determinator/tracking'

module Determinator
  module Tracking
    module Sidekiq
      class Middleware
        # @param [Object] worker the worker instance
        # @param [Hash] job the full job payload
        #   * @see https://github.com/mperham/sidekiq/wiki/Job-Format
        # @param [String] queue the name of the queue the job was pulled from
        # @yield the next middleware in the chain or worker `perform` method
        # @return [Void]
        def call(worker, job, queue)
          begin
            Determinator::Tracking.start!(:sidekiq)
            yield
          rescue => ex
            error = true
            raise
          ensure
            Determinator::Tracking.finish!(
              endpoint: Determinator::Tracking.collect_endpoint_info(worker.class.name),
              queue: queue,
              error: !!error
            )
          end
        end
      end
    end
  end
end
