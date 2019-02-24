namespace :vue do
  desc 'Run vue-cli create and regenerate configuration'
  task :create, [:package_manager] do |_t, args|
    pm = VueCli::Rails::NodeEnv.new
    pm.use!(args.package_manager)
    root = ::Rails.root

    # generate config/vue.yml
    FileUtils.chdir root
    # `vue create .` and dependencies
    pm.exec('vue create', "-n -m #{pm.package_manager} .")
    pm.add '-D webpack-assets-manifest cross-env'
    FileUtils.rm_rf root.join('src')

    # dirs under `app`
    src_dir = Pathname.new(__FILE__).dirname.join('..', 'source')
    FileUtils.cp_r(src_dir.join('app'), root)
    FileUtils.cp(src_dir.join('vue.config.js'), root.join('vue.config.js'))

    yml = src_dir.join('vue.yml').read
    yml = yml.sub('#PACKAGE_MANAGER', pm.package_manager.to_s)
    root.join('config', 'vue.yml').write(yml)
  end

  desc 'Add pug template support: formats=pug,sass,less,stylus'
  task :support, [:formats] do |_t, args|
    pkgs = []
    args.formats.split(/\W/).each do |fmt|
      pkgs += case fmt
              when 'pug'
                %w[pug-plain-loader pug]
              when 'sass', 'scss'
                %w[sass-loader node-sass]
              when 'less'
                %w[less-loader less]
              when 'stylus'
                %w[stylus-loader stylus]
              else
                []
              end
    end
    throw(StandardError, '') if pkgs.empty?
    pm.add "-D #{pkgs.join(' ')}"
  end

  desc 'Dump config/vue.yml to_json'
  task :json_config => :environment do
    config = VueCli::Rails::Configuration.new
    puts config.to_json
  end
end
