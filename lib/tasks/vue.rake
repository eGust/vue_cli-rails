namespace :vue do
  desc 'Run vue-cli create and regenerate configuration'
  task :create do
    require_relative '../helpers/scripts/vue_create'
    VueCreate.run!
  end

  desc 'Add template/style support: formats=pug,slm,sass,less,stylus'
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
    env = { 'RAILS_ENV' => ENV['RAILS_ENV'].presence || ::Rails.env }
    pm.exec('vue-cli-service build', env: env)
    ::Rake::Task['assets:precompile'].invoke if args.with_rails_assets
  end

  desc 'Run JavaScript Lint: alias of vue-cli-service lint'
  task :lint do
    VueCli::Rails::Configuration.instance.node_env.exec('vue-cli-service lint')
  end

  desc 'Run JavaScript unit or e2e tests (default unit-test)'
  task :test, [:unit_e2e] => :environment do |_t, args|
    test = (args.unit_e2e || 'unit').downcase
    abort('Only support test[unit] or test[e2e]') unless %w[unit e2e].include?(test)
    STDERR.puts('WARN: Mocha and E2E tests may not work properly.')
    VueCli::Rails::Configuration.instance.node_env
      .exec("vue-cli-service test:#{test}", env: { 'RAILS_ENV' => 'test' })
  end

  desc 'Install Node way to run Rails dev server alongside webpack-dev-server'
  task node_dev: :environment do
    require_relative '../helpers/scripts/vue_command'
    VueCommand.new.install_node_dev
  end

  desc 'Inspect webpack settings' do
  task inspect: :environment do
    pm = VueCli::Rails::Configuration.instance.node_env
    env = { 'RAILS_ENV' => ENV['RAILS_ENV'].presence || ::Rails.env }
    pm.exec('vue-cli-service inspect', env: env)
  end
end
