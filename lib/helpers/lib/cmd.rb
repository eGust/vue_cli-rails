module Cmd
  def self.run(cmd)
    puts cmd
    system(cmd)
  end
end
