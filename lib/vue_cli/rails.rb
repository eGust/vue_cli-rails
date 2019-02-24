require "vue_cli/rails/version"
require 'vue_cli/rails/configuration'
require 'vue_cli/rails/node_env'

require 'vue_cli/rails/engine' if defined? Rails

module VueCli
  module Rails
    class Error < StandardError; end
  end
end
