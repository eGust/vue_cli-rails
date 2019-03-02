module VueCli
  module Rails
    require 'vue_cli/rails/helper'
    USE_PROXY_MIDDLEWARE = ::Rails.env.development? && defined?(::Rails::Server)
    require 'vue_cli/rails/dev_server_proxy' if USE_PROXY_MIDDLEWARE

    class Engine < ::Rails::Engine
      initializer 'vue_cli' do |app|
        if USE_PROXY_MIDDLEWARE
          app.middleware.insert_before 0, DevServerProxy
          fork do
            config = Configuration.instance
            config.node_env.exec(config['launch_dev_service'] || 'vue-cli-service serve')
          end
        end

        ::ActiveSupport.on_load :action_controller do
          ::ActionController::Base.helper Helper
        end

        ::ActiveSupport.on_load :action_view do
          include Helper
        end
      end
    end
  end
end
