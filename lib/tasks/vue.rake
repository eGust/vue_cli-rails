namespace :vue do
  desc 'Run vue-cli create and regenerate configuration'
  task :create do
    require_relative '../helpers/scripts/vue_create'
    VueCreate.run!
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

    pm = VueCli::Rails::Configuration.instance.node_env
    pm.add "-D #{pkgs.join(' ')}"
  end

  desc 'Dump config/vue.yml to JSON: set [js] to get result from vue.rails.js'
  task :json_config, [:from] => :environment do |_t, args|
    if args.from == 'js'
      cmd = <<~CMD
        node -e "console.log(JSON.stringify(require('./vue.rails.js').getSettings(), null, 2))"
      CMD
      puts "RUN: #{cmd}"
      system(cmd)
    else
      config = VueCli::Rails::Configuration.new
      puts config.to_json
    end
  end

  desc 'Build assets'
  task compile: :environment do
    pm = VueCli::Rails::Configuration.instance.node_env
    pm.exec('vue-cli-service build', env: { 'RAILS_ENV' => ::Rails.env })
  end
end
