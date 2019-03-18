require 'fileutils'
require 'pathname'
require 'pry-byebug'

RSpec.describe VueCli::Rails do
  it 'has a version number' do
    expect(VueCli::Rails::VERSION).not_to be nil
  end
end
