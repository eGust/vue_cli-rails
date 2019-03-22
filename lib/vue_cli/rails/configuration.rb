module VueCli
  module Rails
    class Configuration
      def initialize
        @root = ::Rails.root
        load_config(YAML.load_file(@root.join('config/vue.yml')))
        self.class.setup(self)
      end

      def entry_assets_prod(entry_point)
        self.class.entry_points[entry_point]
      end

      def entry_assets_dev(entry_point)
        assets = Net::HTTP.get(URI("#{self.class.dev_server_url}?#{entry_point}"))
        assets.blank? ? nil : JSON.parse(assets)
      end

      def node_env
        raise(Error, 'Incorrect package_manager in config/vue.yml') if @package_manager.blank?

        @node_env ||= NodeEnv.new do |ne|
          ne.use!(@package_manager)
        end
      end

      JS_CONFIG_CMD = %{
        node -e "console.log(JSON.stringify(require('./vue.rails.js').getSettings(), null, 2))"
      }.strip.freeze

      def load_config(config)
        config = config[::Rails.env]
        entry_path = config['entry_path'].presence || 'app/assets/vue/entry_points'
        c = {
          'configureWebpack' => {
            'entry' => entry(entry_path),
            'resolve' => {},
          },
        }
        @package_manager = config['package_manager']
        cw = c['configureWebpack']

        c['env'] = ::Rails.env
        c['root'] = @root.to_s
        cw['output'] = config['js_output'] if config['js_output'].present?
        c['manifestOutput'] = config['manifest_output']

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

        jest = {}
        c['jestModuleNameMapper'] = jest
        resolve_config(c, 'manifestOutput') if c['manifestOutput'].present?
        config['alias']&.tap do |aliases|
          aliases.each_key do |k|
            key = k.gsub(%r<(?=[-{}()+.,^$#/\s\]])>, '\\')
            path = aliases[k].sub(%r/^\//, '').sub(%r/\/$/, '')
            jest["^#{key}/(.*)$"] = "<rootDir>/#{path}/$1"
            resolve_config(aliases, k)
          end
          cw['resolve']['alias'] = aliases
        end
        dev_server = c['devServer'] || {}
        resolve_config(dev_server, 'contentBase')
      ensure
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

      class << self
        attr_reader :dev_server_url, :entry_points

        def check!
          return if ::Rails.root.join('config/vue.yml').exist?
          abort <<~ERROR
            [ERROR] Failed to load vue_cli-rails!
              Cannot find config file: config/vue.yml
              Please call below command to initialize Vue:
                #{::Rails.version.to_i > 4 ? 'rails' : 'bundle exec rake'} vue:create
          ERROR
        end

        def instance
          @instance ||= new
        end

        def setup(config)
          config.dev_server_host.presence&.tap do |host|
            @dev_server_url = "http://#{host}/__manifest/"
          end

          @entry_points = {}
          manifest = config['manifestOutput'].presence
          manifest &&= Pathname.new(manifest)
          if manifest&.exist?
            @entry_points = (JSON.parse(manifest.read || '{}')['entrypoints'] || {}).freeze
          end
        end
      end

      private

      def resolve(*path)
        @root.join(*path).to_s
      end

      def entry(entry_path)
        base_dir = @root.join(entry_path)
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
