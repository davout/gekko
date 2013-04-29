# coding: utf-8

lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'gekko/version'

Gem::Specification.new do |s|
  s.name        = 'gekko'
  s.version     = Gekko::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['David FRANCOIS']
  s.email       = ['david@bitcoin-central.net']
  s.homepage    = 'https://bitcoin-central.net/'
  s.summary     = 'A powerful and scalable order matching engine'
  s.description = ''

  s.required_rubygems_version = '>= 1.3.6'

  #s.add_dependency 'uuidtools'

  s.add_development_dependency 'rspec'
  #s.add_development_dependency 'vcr'
  #s.add_development_dependency 'webmock'
  s.add_development_dependency 'rake'

  s.files        = Dir.glob('{bin,lib}/**/*') + %w(LICENSE README.md)
  s.executables  = ['gekko']
  s.require_path = 'lib'
end
