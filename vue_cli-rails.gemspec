lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'vue_cli/rails/version'

Gem::Specification.new do |spec|
  spec.name          = 'vue_cli-rails'
  spec.version       = VueCli::Rails::VERSION
  spec.authors       = ['James Chen']
  spec.email         = ['egustc@gmail.com']

  spec.summary       = 'Get vue-cli working with Rails'
  spec.homepage      = 'https://github.com/eGust/vue_cli-rails'
  spec.license       = 'MIT'

  spec.files         = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.3'

  spec.add_dependency 'activesupport', '>= 4.2'
  spec.add_dependency 'rack-proxy',    '>= 0.6'
  spec.add_dependency 'railties',      '>= 4.2'

  spec.add_development_dependency 'bundler', '~> 1.12'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'pry-byebug'
end
