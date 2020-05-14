require 'determinator/tracking'

module Determinator
  module Tracking
    module Rack
      class Middleware
        def initialize(app)
          @app = app
        end

        def call(env)
          Determinator::Tracking.start!(:rack)
          status, headers, response = @app.call(env)
          [status, headers, response]
        rescue
          error = true
          raise
        ensure
          Determinator::Tracking.finish!(
            status: status,
            error: !!error,
            endpoint: extract_endpoint(env)
          )
        end

        private

        def extract_endpoint(env)
          parts = if params = env['action_dispatch.request.path_parameters']
            [[params[:controller], params[:action]].join('#')]
          else
            [env['REQUEST_METHOD'], env['PATH_INFO'] || env['REQUEST_URI']]
          end
          Determinator::Tracking.collect_endpoint_info(parts)
        rescue
          env['PATH_INFO']
        end
      end
    end
  end
end
