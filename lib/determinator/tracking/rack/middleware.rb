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
          Determinator::Tracking.finish!(status: status, error: !!error)
        end
      end
    end
  end
end
