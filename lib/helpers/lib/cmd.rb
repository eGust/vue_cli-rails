module Cmd
  def self.run(cmd)
    STDERR.puts cmd
    system(cmd)
  end
end
