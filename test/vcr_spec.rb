#!/usr/bin/env rspec

require 'rspec'
require 'fileutils'
require 'pathname'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

RSpec.describe 'vue_cli-rails demo is runable' do
  before :all do
    @cwd = Pathname.new(__dir__).join('vcdr')
    Dir.chdir(@cwd)
    @env = %x`which env`.chomp
  end

  it 'can invoke vue:lint' do
    expect(%x(#{@env} bundle exec rake vue:lint)).to include('No lint errors found')
  end

  it 'can invoke vue:test[unit]' do
    expect(%x(bundle exec rake vue:test[unit] 2>&1)).to include('1 passed, 1 total')
  end

  it 'can build assets' do
    expect {
      %x(#{@env} RAILS_ENV=production bundle exec rake vue:compile[with_rails_assets])
    }.not_to raise_error
    expect(@cwd.join('app/assets/vue/manifest.json').exist?).to be true
  end

  it 'can add supports' do
    expect {
      %x(#{@env} bundle exec rake vue:support[pug,slm,sass,less,stylus])
    }.not_to raise_error
  end

  it 'can run yarn lint' do
    expect {
      %x(#{@env} RAILS_ENV=test yarn lint)
    }.not_to raise_error
  end

  it 'can run yarn test:unit' do
    expect {
      %x(#{@env} RAILS_ENV=test yarn test:unit)
    }.not_to raise_error
  end

  it 'can add vue:node_dev and run yarn prod' do
    expect {
      %x(#{@env} bundle exec rake vue:node_dev)
    }.not_to raise_error
    expect {
      %x(#{@env} yarn prod)
    }.not_to raise_error
  end
end
