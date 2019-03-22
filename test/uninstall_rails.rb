#!/usr/bin/env ruby

require_relative '../lib/helpers/lib/common'

def get_rails_version
  ver = ARGV[0].presence || ENV['RAILS_VERSION']
  versions = %x`gem list -e activesupport`.scan(/\b((\d+\.)+\w+)\b/).map { |m| m[0] }
  if ver.blank?
    abort <<~TEXT
      Must specify a Rails version!
        Installed versions: #{versions.join(' ')}
    TEXT
  end

  unless versions.include?(ver)
    abort <<~TEXT
      Version (#{ver}) does not exist in the system
        available versions: #{versions.join(' ')}
    TEXT
  end
  ver
end

KNOWN_GEMS = %w[
  rails
  railties

  actioncable
  actionmailbox
  actionmailer
  actiontext
  activejob

  activestorage
  activerecord
  activemodel
  actionpack
  actionview
  activesupport
]

def main
  ver = get_rails_version
  re = %r{\b#{ver.tr('.', '\.')}\b}
  KNOWN_GEMS.each do |gem|
    next unless %x[gem list -e #{gem}] =~ re
    puts %x[gem uninstall #{gem} -v #{ver}]
  end
  puts "Done! - Rails #{ver} should be uninstalled"
end

main
