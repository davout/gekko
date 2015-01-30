require 'pry'

require 'simplecov'
require 'coveralls'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
]

SimpleCov.start do
  add_filter '/spec/'
end

require(File.expand_path('../../lib/gekko', __FILE__))

def random_id
  UUID.random_create
end

def populate_book(book, orders)
  orders[:bids].each { |b| book.receive_order(Gekko::Order.new(:bid, random_id, b[0], b[1])) }
  orders[:asks].each { |b| book.receive_order(Gekko::Order.new(:ask, random_id, b[0], b[1])) }
end

