module VueCli
  module Rails
    require 'vue_cli/rails/helper'

    class Engine < ::Rails::Engine
      initializer 'vue_cli' do |app|
        if ::Rails.env.development? && defined?(::Rails::Server)
          require 'vue_cli/rails/dev_server_proxy'
          app.middleware.insert_before(0, DevServerProxy)
          Engine.start_wds! if ENV['NO_WEBPACK_DEV_SERVER'].blank?
        end

        ::ActiveSupport.on_load(:action_controller) do
          ::ActionController::Base.helper(Helper)
        end

        ::ActiveSupport.on_load(:action_view) do
          include Helper
        end
      end

      def self.start_wds!
        fork do
          config = Configuration.instance
          port = config['devServer']&.dig('port')
          if port
            running = %x`lsof -i:#{port} -sTCP:LISTEN -Pn`&.chop.presence&.split("\n")
            pid = running&.dig(1)&.split(/\s+/, 3)&.dig(1)
            Process.kill('INT', pid.to_i) if pid.present?
          end
          config.node_env.exec(config['launch_dev_service'] || 'vue-cli-service serve')
        end
      end
    end
  end
end
