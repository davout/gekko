# coding: utf-8

lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'gekko/version'

Gem::Specification.new do |s|
  s.name        = 'gekko'
  s.version     = Gekko::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['David FRANCOIS']
  s.email       = ['david.francois@paymium.com']
  s.homepage    = 'https://paymium.com'
  s.summary     = 'An in-memory order matching engine.'
  s.description = 'Gekko is a bare-bones order matcher whose task is to accept orders and maintain an order book.'
  s.licenses    = ['MIT']

  s.required_rubygems_version = '>= 1.3.6'

  s.add_dependency 'uuidtools', '~> 2.1'
  s.add_dependency 'oj',        '~> 2.0'

  s.add_development_dependency 'pry',       '~> 0.10'
  s.add_development_dependency 'rspec',     '~> 3.1'
  s.add_development_dependency 'rake',      '~> 10.3'
  s.add_development_dependency 'yard',      '~> 0.8'
  s.add_development_dependency 'timecop',   '~> 0.7'
  s.add_development_dependency 'redcarpet', '~> 3.1'
  s.add_development_dependency 'simplecov', '~> 0.9'
  s.add_development_dependency 'coveralls', '~> 0.7'

  s.files = Dir.glob('lib/**/*') + %w(LICENSE README.md)

  s.require_path = 'lib'
end
