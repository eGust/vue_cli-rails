namespace :vue do
  desc 'Run vue-cli create and regenerate configuration'
  task :create do
    require_relative '../helpers/scripts/vue_create'
    VueCreate.run!
  end

  desc 'Add template/style support: formats=pug,sass,less,stylus'
  task :support, [:formats] do |_t, args|
    require_relative '../helpers/scripts/vue_command'
    VueCommand.new.install_format_support(args.formats&.split(/\W/))
  end

  desc 'Dump config/vue.yml to JSON: set [js] to get result from vue.rails.js'
  task :json_config, [:from] => :environment do |_t, args|
    if args.from == 'js'
      require_relative '../helpers/lib/cmd'
      Cmd.run(VueCli::Rails::Configuration::JS_CONFIG_CMD)
    else
      config = VueCli::Rails::Configuration.new
      puts config.to_json
    end
  end

  desc 'Build assets: set [with_rails_assets] to invoke assets:precompile as well'
  task :compile, [:with_rails_assets] => :environment do |_t, args|
    pm = VueCli::Rails::Configuration.instance.node_env
    pm.exec('vue-cli-service build', env: { 'RAILS_ENV' => ::Rails.env })
    ::Rake::Task['assets:precompile'].invoke if args.with_rails_assets
  end

  desc 'Install Node way to run Rails dev server alongside webpack-dev-server'
  task node_dev: :environment do
    require_relative '../helpers/scripts/vue_command'
    VueCommand.new.install_node_dev
  end
end
