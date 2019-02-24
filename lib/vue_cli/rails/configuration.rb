module VueCli
  module Rails
    class Configuration
      def initialize
        @root = ::Rails.root
        load_config(YAML.load_file(@root.join('config/vue.yml')))
      end

      def node_env
        @node_env ||= NodeEnv.new do |ne|
          ne.use! @config['package_manager']
        end
      end

      def load_config(config)
        r_env = ::Rails.env
        config = config[r_env]
        config['env'] = r_env
        config['root'] = @root.to_s
        config['entry'] = entry

        public_output_path = config['public_output_path'] || 'vue_assets'
        config['outputDir'] = File.join(resolve('public'), public_output_path)
        config['publicPath'] = File.join('/', public_output_path, '/')
        resolve_config(config, 'manifestOutput')

        cfg_alias = config['alias']
        cfg_alias.keys.each { |k| resolve_config(cfg_alias, k) }
        dev_server = config['devServer'] || {}
        resolve_config(dev_server, 'contentBase')

        self.class.manifest_file = config['manifestOutput']
        @config = config
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
        @config.to_json
      end

      def manifest_data
        self.class.manifest.data
      end

      class << self
        def instance
          @instance ||= new
        end

        def manifest_file=(val)
          @manifest_file = Pathname.new(val)
        end

        def manifest
          @manifest ||= OpenStruct.new(mtime: nil, data: {})
          if @manifest_file.exist? && @manifest.mtime != @manifest_file.mtime
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
        config[key] = resolve(path) if path.present?
      end
    end
  end
end
