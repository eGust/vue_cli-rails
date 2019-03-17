#!/usr/bin/env ruby
require 'pathname'
require 'fileutils'
require 'set'
require 'pry-byebug'

require_relative '../lib/helpers/lib/common'
require_relative '../lib/helpers/lib/cmd'

USAGE = <<~TEXT
  Usage
    set RAILS_VERSION to 4, 5 or latest and run this command
  Example
    /usr/bin/env RAILS_VERSION=4 #{__FILE__}
TEXT

ver = ENV['RAILS_VERSION']
abort("RAILS_VERSION not found!\n#{USAGE}") if ver.blank?

versions = %x`gem list -r -a -e rails`.scan(/\b((\d+\.)+\d+)\b/).map { |m| m[0] }
ver = ver.upcase == 'LATEST' ? versions.first : versions.find { |v| v.start_with?(ver) }
abort("Can not find matched Rails version!\n#{USAGE}") if ver.blank?

Cmd.run("gem install rails -v #{ver}") unless %x`gem list -e rails`.include?(ver)

args = []
white_list = []
append_lines = ''
if ver.start_with?('4')
  args = %w[
    --database=sqlite3
    --skip-bundle
    --skip-git
    --skip-keeps
    --skip-turbolinks
    --skip-test-unit
  ]
  white_list = %w[
    rails
    sass-rails
    uglifier
    jquery-rails
    spring
  ]
  append_lines = <<~RUBY
    gem 'puma'
  RUBY
elsif ver.start_with?('5')
  args = %w[
    --database=sqlite3
    --skip-git
    --skip-keeps
    --skip-bundle
    --skip-yarn
    --skip-turbolinks
    --skip-listen
    --skip-coffee
    --skip-test
  ]
  white_list = %w[
    rails
    puma
    sass-rails
    uglifier
    bootsnap
    jquery-rails
    spring
    spring-watcher-listen
  ]
else
  abort("Unsupported Rails version: #{ver}!\n#{USAGE}")
end

dest_dir = Pathname.new(__dir__).join('vcdr')
FileUtils.rm_rf(dest_dir) if dest_dir.exist?
Cmd.run("rails _#{ver}_ new vcdr #{args.join(' ')}")

white_list = Set.new(white_list)
gem_lines = dest_dir.join('Gemfile').read.split("\n")
gem_lines = gem_lines.reject { |line| line =~ /^(git_source|ruby|\s*#)/ }
  .reject do |line|
    m = line.match(/^\s*gem\s+['"](.+?)['"]/)
    m && !white_list.include?(m[1])
  end
gem_lines << "\n\n#{append_lines}"
gem_lines << <<~RUBY
  gem 'vue_cli-rails', path: '../../'
  gem 'sqlite3', '~> 1.3.0'
RUBY
dest_dir.join('Gemfile').write(gem_lines.join("\n").gsub(/\n{3,}/, "\n\n"))

FileUtils.chdir(dest_dir)
Cmd.run('bundle install')
Cmd.run('bundle exec rake vue:create')
