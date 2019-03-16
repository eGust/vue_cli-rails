require_relative '../lib'

class VueCommand
  SASS = %w[sass-loader node-sass].freeze

  SUPPORED_FORMATS = {
    'pug' => %w[pug-plain-loader pug],
    'slm' => %w[slm-loader slm],
    'sass' => SASS,
    'scss' => SASS,
    'less' => %w[less-loader less],
    'stylus' => %w[stylus-loader stylus],
  }.freeze

  def initialize
    @pm = VueCli::Rails::Configuration.instance.node_env
  end

  def install_format_support(formats)
    pkgs, unknown = group_formats(formats)
    if pkgs.empty?
      msg = unknown.empty? ? 'No formats supplied' : "Unsupported formats #{unknown}"
      raise(ArgumentError, msg)
    end

    STDERR.puts "Unsupported formats #{unknown}" if unknown.any?
    @pm.add("-D #{pkgs.join(' ')}")
  end

  def install_node_dev
    pack_json = ::Rails.root.join('package.json')
    abort('Not found package.json!') unless pack_json.exist? && pack_json.file?

    add_deps(pack_json, %w[cross-env npm-run-all])
    add_scripts(pack_json,
      dev: 'run-p rails-s serve',
      prod: 'cross-env RAILS_ENV=production vue-cli-service build',
      serve: 'vue-cli-service serve',
      'rails-s' => 'cross-env NO_WEBPACK_DEV_SERVER=1 rails s')
    puts 'Dependencies and scripts have been installed successfully'
    cmd = @pm.package_manager == :npm ? 'npm run' : 'yarn'
    puts "  Please use `#{cmd} dev` to start dev server"
  end

  private

  def add_deps(package_json, *packages, dev: true)
    json = JSON.parse(package_json.read)
    deps = json[dev ? 'devDependencies' : 'dependencies']
    pkgs = [packages].flatten.find_all do |dep|
      !(dep.blank? || deps.key?(dep))
    end
    @pm.add("#{dev ? '-D ' : ''}#{pkgs.join(' ')}") if pkgs.any?
  end

  def add_scripts(package_json, commands = {})
    json = JSON.parse(package_json.read)
    scripts = json['scripts']
    commands.stringify_keys.each do |key, cmd|
      scripts[key] = cmd unless scripts.key?(key)
    end
    package_json.write(JSON.pretty_generate(json))
  end

  def group_formats(formats)
    formats.each_with_object([[], []]) do |fmt, result|
      fmts = SUPPORED_FORMATS[fmt.downcase]
      if fmts
        result[0] += fmts
      else
        result[1] << fmt
      end
    end
  end
end
