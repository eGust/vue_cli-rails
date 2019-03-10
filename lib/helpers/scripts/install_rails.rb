#!/usr/bin/env ruby
require_relative 'common'

ver = ENV['RAILS_VERSION']
abort('RAILS_VERSION not found!') if ver.blank?

versions = %x`gem list -r -a -e rails`.scan(/\b((\d+\.)+\d+)\b/).map { |m| m[0] }
ver = versions.find { |v| v.start_with?(ver) }
abort("Version #{ver} not found!") if ver.blank?

run("gem install rails -v #{ver}")

RAILS_NEW_SCRIPT = {
  '5' => {
    args: %w[
      database=sqlite3
      skip-yarn
      skip-git
      skip-keeps
      skip-sprockets
      skip-spring
      skip-listen
      skip-turbolinks
      skip-javascript
      skip-test
      skip-bundle
    ],
    keep_gems: /^\s*gem\s+['"](rails|puma|bootsnap)/,
    append: "gem 'sqlite3', '~> 1.3.10'",
  },
}

require 'pathname'
require 'fileutils'

scirpt = RAILS_NEW_SCRIPT[ver[0]]
run("rails new test_vcr #{scirpt[:args].map { |a| "--#{a}" }.join(' ')}")
FileUtils.chdir('test_vcr')

root = Pathname.new(FileUtils.pwd)
gemfile = root.join('Gemfile').read.split("\n")
  .reject(&:empty?).reject { |s| s =~ /^\s*#/ }
  .reject { |s| s =~ /^\s*gem/ && s !~ scirpt[:keep_gems] }
root.join('Gemfile').write("#{(gemfile + [scirpt[:append]]).join("\n")}\n")
run('bundle install')
