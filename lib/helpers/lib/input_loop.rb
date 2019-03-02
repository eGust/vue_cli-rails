class InputLoop
  DEFAULT_HINT = { 'y' => 'Yes', 'n' => 'No' }.freeze

  def gets(message, list = 'Yn', **hint)
    default, list = build_list(list)
    keys_hint, hint = build_hint(list, hint)

    print "#{message} (#{hint}) #{keys_hint}"
    wait_valid_input(keys_hint, Set.new(list.map(&:downcase)), default)
  end

  private

  def wait_valid_input(keys_hint, keys, default)
    loop do
      r = STDIN.gets.chop.downcase
      break default if r == ''
      break r if keys.include?(r)

      print "  [INVALID!] Please retry: #{keys_hint}:"
    end
  end

  def build_list(list)
    list = list.chars
    default = list.find { |c| c.upcase == c }
    [default.downcase, list.map { |c| c == default ? c : c.downcase }.uniq]
  end

  def build_hint(list, hint)
    valid = "[#{list.join('')}]"
    hint = DEFAULT_HINT.merge(hint.map { |k, v| [k.to_s.downcase, v] }.to_h)
    hint = list.map do |c|
      h = hint[c.downcase]
      next if h.blank?

      "#{c.upcase}=#{h}"
    end
    [valid, hint.join(', ')]
  end
end
