require 'simplecov'

SimpleCov.start do
  add_filter '/spec/'
end

require(File.expand_path('../../lib/gekko', __FILE__))

def random_id
  UUID.random_create
end

