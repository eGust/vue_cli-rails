module VueCli
  module Rails
    class Configuration
      def initialize
        @root = ::Rails.root
        load_config(YAML.load_file(@root.join('config/vue.yml')))
      end

      def node_env
        raise(Error, 'Incorrect package_manager in config/vue.yml') if @package_manager.blank?

        @node_env ||= NodeEnv.new do |ne|
          ne.use! @package_manager
        end
      end

      JS_CONFIG_CMD = %{
        node -e "console.log(JSON.stringify(require('./vue.rails.js').getSettings(), null, 2))"
      }.strip.freeze

      def load_config(config)
        config = config[::Rails.env]
        c = {
          'configureWebpack' => {
            'entry' => entry,
            'resolve' => {},
          },
        }
        @package_manager = config['package_manager']
        cw = c['configureWebpack']

        c['env'] = ::Rails.env
        c['root'] = @root.to_s
        cw['output'] = config['js_output'] if config['js_output'].present?
        c['manifestOutput'] = config['manifest_output']
        unless c['manifestOutput'].presence
          raise(Error, 'Incorrect manifest_output in config/vue.yml')
        end

        public_output_path = c['public_output_path'] || 'vue_assets'
        c['outputDir'] = File.join(resolve('public'), public_output_path)
        c['publicPath'] = File.join('/', public_output_path, '/')

        %w[
          launch_node
          modern

          filenameHashing
          lintOnSave
          runtimeCompiler
          transpileDependencies
          productionSourceMap
          crossorigin
          css
          devServer
          parallel
          pwa
          pluginOptions
        ].each { |k| c[k] = config[k] if config.key?(k) }

        resolve_config(c, 'manifestOutput')
        config['alias']&.tap do |aliases|
          aliases.each_key { |k| resolve_config(aliases, k) }
          cw['resolve']['alias'] = aliases
        end
        dev_server = c['devServer'] || {}
        resolve_config(dev_server, 'contentBase')

        self.class.manifest_file = c['manifestOutput']
        @config = c
      end

      def [](path)
        @config[path]
      end

      def output_url_path
        @config['publicPath']
      end

      def dev_server_host
        dev_server = @config['devServer']
        dev_server ? "#{dev_server['host'] || localhost}:#{dev_server['port'] || 8080}" : nil
      end

      def to_json
        JSON.pretty_generate(@config)
      end

      def manifest_data
        self.class.manifest.data
      end

      class << self
        def instance
          @instance ||= new
        end

        def manifest_file=(val)
          @manifest_file = val ? Pathname.new(val) : nil
        end

        def manifest
          @manifest ||= OpenStruct.new(mtime: nil, data: {})
          if @manifest_file&.exist? && @manifest.mtime != @manifest_file.mtime
            @manifest.mtime = @manifest_file.mtime
            @manifest.data = JSON.parse(@manifest_file.read)
          end
          @manifest
        end
      end

      private

      def resolve(*path)
        @root.join(*path).to_s
      end

      def entry
        base_dir = @root.join('app/assets/vue/views')
        start = base_dir.to_s.size + 1
        Dir[base_dir.join('**/*.js')].each_with_object({}) do |filename, h|
          h[filename[start...-3]] = filename
        end
      end

      def resolve_config(config, key, default = nil)
        path = config[key] || default
        config[key] = resolve(path) if path.present? && path.is_a?(String)
      end
    end
  end
end
