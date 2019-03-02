module VueCli
  module Rails
    class NodeEnv
      NODE_BIN_LIST = %i[node yarn npm npx vue].freeze

      def initialize
        @versions = {}
        yield(self) if block_given?
      end

      def use!(manager)
        @pm = manager.to_sym
        raise(ArgumentError, "Unsupported manager: #{@pm}") unless %i[npm yarn].include?(@pm)
        raise(VueCli::Rails::Error, "Not installed: #{@pm}") unless try(:"#{@pm}?")
      end

      def reset
        @versions = {}
      end

      NODE_BIN_LIST.each do |bin|
        define_method :"#{bin}_version" do
          get_version_of(bin)
        end

        define_method :"#{bin}?" do
          get_version_of(bin).present?
        end
      end

      def package_manager
        @pm
      end

      def exec(command, args = nil, extra = nil, env: {})
        cmd = COMMAND_LINE[command.to_sym] || {}
        cmd = if @pm == :yarn && cmd[:yarn]
                cmd[:yarn]
              elsif @pm == :npm && cmd[:npm]
                cmd[:npm]
              elsif cmd[:npx]
                @pm == :yarn ? "yarn exec #{cmd[:npx]}" : "npx #{cmd[:npx]}"
              else
                @pm == :yarn ? "yarn exec #{command}" : "npx #{command}"
              end

        cmd = "#{cmd} #{args}" if args.present?
        cmd = "#{cmd} #{@pm == :yarn ? '-- ' : ''}#{extra}" if extra.present?
        puts "run: #{cmd}"
        system(env, cmd)
      end

      COMMAND_LINE = {
        global_add: {
          yarn: 'yarn global add',
          npm: 'npm i -g',
        },
        install: {
          yarn: '',
          npm: 'npm i',
        },
      }.freeze

      def method_missing(cmd, *args)
        exec(cmd, *args)
      end

      private

      def get_version_of(bin)
        return @versions[bin] if @versions.key?(bin)

        r = begin
              `#{bin} --version`.strip.presence
            rescue StandardError
              nil
            end
        @versions[bin] = r&.start_with?('v') ? r[1..-1] : r
        @versions[bin]
      end
    end
  end
end
