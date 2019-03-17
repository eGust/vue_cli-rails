module VueCli
  module Rails
    require 'vue_cli/rails/helper'

    class Engine < ::Rails::Engine
      initializer 'vue_cli' do |app|
        if defined?(::Rails::Server)
          Configuration.check!
          is_dev = ::Rails.env.development?

          if is_dev
            require 'vue_cli/rails/dev_server_proxy'

            app.middleware.insert_before(0, DevServerProxy)
            Engine.start_wds! if ENV['NO_WEBPACK_DEV_SERVER'].blank?
          end

          Configuration.class_eval do
            alias_method :entry_assets, :"entry_assets_#{is_dev ? 'dev' : 'prod'}"
            remove_method :entry_assets_dev, :entry_assets_prod
          end
          Configuration.instance unless is_dev
        end

        ::ActionController::Renderers.add(:vue) do |entry, options|
          render({ html: vue_entry(entry), layout: true }.merge(options))
        end

        ::ActiveSupport.on_load(:action_controller) do
          ::ActionController::Base.class_eval do
            helper(Helper)
            include(Helper)
          end
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

          cmd = config['launch_dev_service'].presence || 'vue-cli-service serve'
          config.node_env.exec(cmd)
        end
      end
    end
  end
end
