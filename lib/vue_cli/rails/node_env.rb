module VueCli
  module Rails
    class NodeEnv
      NODE_BIN_LIST = %i[node yarn npm npx vue].freeze

      def initialize
        h = {}
        NODE_BIN_LIST.each do |bin|
          h[bin] = get_version_of(bin)
        end
        @versions = h
        yield(self) if block_given?
      end

      NODE_BIN_LIST.each do |bin|
        define_method :"#{bin}_version" do
          @versions[bin]
        end

        define_method :"#{bin}?" do
          @versions[bin].present?
        end
      end

      def use!(pm)
        @pm = (pm || (yarn? ? 'yarn' : 'npm')).to_sym
        unless (@pm == :npm || @pm == :yarn) && self.try(:"#{@pm}?")
          raise(VueCli::Rails::Error, "Unknown package manager: #{@pm}")
        end
      end

      def package_manager
        @pm
      end

      def exec(command, args = nil)
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

        cmd = "#{cmd} #{@pm == :yarn ? '-- ' : ''}#{args}" if args.present?
        puts "run: #{cmd}"
        system(cmd)
      end

      COMMAND_LINE = {
        add: {
          yarn: 'yarn add',
          npm: 'npm i -S',
        }
      }.freeze

      def method_missing(cmd, *args)
        exec(cmd, *args)
      end

      private

      def get_version_of(bin)
        r = `#{bin} --version`.strip.presence
        return nil if r.nil?

        r.start_with?('v') ? r[1..-1] : r
      end

      def version_ge?(v1, v2)
        Gem::Version.new(v1) >= Gem::Version.new(v2)
      end
    end
  end
end
