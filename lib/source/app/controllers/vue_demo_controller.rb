class VueDemoController < ApplicationController
  layout 'vue_demo'

  def bar
    render vue: 'bar' # same as `render html: vue_entry('bar'), layout: true`
  end

  def baz
    render html: vue_entry('foo') # same as `render vue: 'foo', layout: false`
  end
end
