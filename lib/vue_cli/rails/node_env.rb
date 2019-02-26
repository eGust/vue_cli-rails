module VueCli
  module Rails
    class NodeEnv
      NODE_BIN_LIST = %i[node yarn npm npx vue].freeze

      def initialize
        @versions = {}
        yield(self) if block_given?
      end

      NODE_BIN_LIST.each do |bin|
        define_method :"#{bin}_version" do
          get_version_of(bin)
        end

        define_method :"#{bin}?" do
          get_version_of(bin).present?
        end
      end

      def use!(pm)
        @pm = pm.to_sym
        raise(ArgumentError, "Unsupported manager: #{@pm}") unless %i[npm yarn].include?(@pm)
        raise(VueCli::Rails::Error, "Not installed: #{@pm}") unless self.try(:"#{@pm}?")
      end

      def package_manager
        @pm
      end

      def exec(command, args = nil, extra = nil, env: {})
        cmd = COMMAND_LINE[command.to_sym] || {}
        if @pm == :yarn && cmd[:yarn]
          cmd = cmd[:yarn]
        elsif @pm == :npm && cmd[:npm]
          cmd = cmd[:npm]
        elsif cmd[:npx]
          cmd = @pm == :yarn ? "yarn exec #{cmd[:npx]}" : "npx #{cmd[:npx]}"
        else
          cmd = @pm == :yarn ? "yarn exec #{command}" : "npx #{command}"
        end

        cmd = "#{cmd} #{args}" if args.present?
        cmd = "#{cmd} #{@pm == :yarn ? '-- ' : ''}#{extra}" if extra.present?
        puts "run: #{cmd}"
        system(env, cmd)
      end

      COMMAND_LINE = {
        add: {
          yarn: 'yarn add',
          npm: 'npm i -S',
        },
        global_add: {
          yarn: 'yarn global add',
          npm: 'npm i -g'
        },
      }.freeze

      def method_missing(cmd, *args)
        exec(cmd, *args)
      end

      private

      def get_version_of(bin)
        return @versions[bin] if @versions.key?(bin)

        r = `#{bin} --version`.strip.presence rescue nil
        @versions[bin] = r && r.start_with?('v') ? r[1..-1] : r
        @versions[bin]
      end

      def version_ge?(v1, v2)
        Gem::Version.new(v1) >= Gem::Version.new(v2)
      end
    end
  end
end
