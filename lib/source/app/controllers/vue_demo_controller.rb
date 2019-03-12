class VueDemoController < ApplicationController
  layout 'vue_demo'

  def bar
    render_vue 'bar'
  end

  def baz
    render html: vue_entry('foo')
  end
end
