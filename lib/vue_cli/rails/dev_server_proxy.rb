require 'rack/proxy'

module VueCli
  module Rails
    class DevServerProxy < ::Rack::Proxy
      def initialize(app)
        @app = app
        config = Configuration.instance
        @host = config.dev_server_host
        @assets_path = config.output_url_path
      end

      def perform_request(env)
        if env['PATH_INFO'].start_with?(@assets_path)
          env['HTTP_HOST'] = env['HTTP_X_FORWARDED_HOST'] = env['HTTP_X_FORWARDED_SERVER'] = @host
          env['HTTP_X_FORWARDED_PROTO'] = env['HTTP_X_FORWARDED_SCHEME'] = 'http'
          env['SCRIPT_NAME'] = ''
          super(env)
        else
          @app.call(env)
        end
      end
    end
  end
end
