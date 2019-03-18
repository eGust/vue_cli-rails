#!/usr/bin/env ruby

require 'expect'
require 'fileutils'
require 'pathname'
require 'pty'
require 'set'

require_relative '../lib/helpers/lib/common'
require_relative '../lib/helpers/lib/cmd'

USAGE = <<~TEXT
  Usage
    set RAILS_VERSION to 4, 5 or latest and run this command
  Example
    /usr/bin/env RAILS_VERSION=4 #{__FILE__}
TEXT

def wait(r, expect = nil)
  loop do
    begin
      line = r.read_nonblock(4000)
    rescue => e
      puts "wait exception: #{e}" unless e.is_a?(IO::EAGAINWaitReadable)
      sleep(0.0625) # 16 fps
      next
    end

    print line
    return line if expect ? line.include?(expect) : true
  end
end

def simple_answer(r, w, expect, answer = '', line: nil)
  sleep(0.125)
  line ||= wait(r)
  if line.include? expect
    w.write "#{answer}\n"
    w.flush
    return
  end
  line
end

def wait_answer(r, w, expect, answer = '')
  loop do
    line = wait(r)
    if line.include? expect
      w.write "#{answer}\n"
      w.flush
      return
    end
  end
end

def select_single(r, w, expect, keyword, line: nil)
  line ||= wait(r)
  return line unless line.include? expect

  keyword = keyword.downcase
  loop do
    line.force_encoding('UTF-8')
    current = line.split("\n").find { |ln| ln.include? "\xE2\x9D\xAF" }
    if current.downcase.include? keyword
      w.write "\n"
      return
    end
    w.write "\e[B"
    line = wait(r)
  end
end

def select_multiple(r, w, expect, targets, line: nil)
  line ||= wait(r)
  return line unless line.include? expect

  loop do
    line.force_encoding('UTF-8')
    options = line.split("\n").map(&:chomp)

    selected = options.find_all { |ln| ln.include? "\xE2\x97\x89" }
      .each_with_object({}) do |ln, h|
        feat = targets.find { |f| ln.include? f }
        h[feat || ln.split(' ')[-1]] = true
      end.keys
    if selected - targets == targets - selected
      w.write "\n"
      return
    end

    current = options.find { |ln| ln.include? "\xE2\x9D\xAF" }
    cur_is_sel = current.include? "\xE2\x97\x89"
    cur_is_tag = !!targets.find { |f| current.include? f }

    if cur_is_sel ^ cur_is_tag
      w.write " "
      line = wait(r)
      next
    end
    w.write "\e[B"
    line = wait(r)
  end
end

def yield_args_by_rails(ver)
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
  [args, white_list, append_lines]
end

def update_gemfile(cwd, white_list, append_lines)
  white_list = Set.new(white_list)
  gem_lines = cwd.join('Gemfile').read.split("\n")
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
  cwd.join('Gemfile').write(gem_lines.join("\n").gsub(/\n{3,}/, "\n\n"))
end

def rails_ver
  ver = ENV['RAILS_VERSION']
  abort("RAILS_VERSION not found!\n#{USAGE}") if ver.blank?

  versions = %x`gem list -r -a -e rails`.scan(/\b((\d+\.)+\d+)\b/).map { |m| m[0] }
  ver = ver.upcase == 'LATEST' ? versions.first : versions.find { |v| v.start_with?(ver) }
  abort("Can not find matched Rails version!\n#{USAGE}") if ver.blank?
  ver
end

def auto_install(pm = 'yarn')
  PTY.spawn('bundle exec rake vue:create 2>&1') do |r, w, _pid|
    STDERR.puts '--'
    STDERR.puts 'bundle exec rake vue:create'
    STDERR.puts 'AUTO FILL-UP'
    STDERR.puts ''

    simple_answer(r, w, 'Which package manager', pm == 'yarn' ? 'y' : 'n')
    wait_answer(r, w, 'Generate project in current directory')

    ln = select_single(r, w, 'Please pick a preset', 'Manually select features')
    # E2E is not available yet
    ln = select_multiple(r, w, 'Check the features needed', %w[Babel Linter Unit], line: ln)
    ln = select_single(r, w, 'Pick a linter / formatter', 'Airbnb', line: ln)
    ln = select_multiple(r, w, 'Pick additional lint features', [], line: ln)
    ln = select_single(r, w, 'Pick a unit testing', 'Jest', line: ln)
    ln = select_single(r, w, 'Pick a E2E testing', 'Cypress', line: ln)
    ln = select_single(r, w, 'Where do you prefer placing config', 'dedicated', line: ln)
    ln = simple_answer(r, w, 'Save this as a preset', line: ln)
    select_single(r, w, 'Pick the package manager to use', pm, line: ln)

    wait_answer(r, w, 'Do you want to delete')
    wait_answer(r, w, 'Do you want to copy demo', 'y')

    puts "waiting finish"
    wait(r, 'vue:create finished')
  end
end

def main
  ver = rails_ver
  Cmd.run("gem install rails -v #{ver}") unless %x`gem list -e rails`.include?(ver)

  dest_dir = Pathname.new(__dir__).join('vcdr')
  FileUtils.rm_rf(dest_dir) if dest_dir.exist?

  args, white_list, append_lines = yield_args_by_rails(ver)
  puts %x{rails _#{ver}_ -v}
  Cmd.run("rails _#{ver}_ new vcdr #{args.join(' ')}")
  FileUtils.chdir(dest_dir)

  update_gemfile(dest_dir, white_list, append_lines)
  Cmd.run('bundle install')
  auto_install
end

main
