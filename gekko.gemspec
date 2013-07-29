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
  s.description = 'Gekko works by spawning an EventMachine-based network listener that communicates with matching processes through Redis'

  s.required_rubygems_version = '>= 1.3.6'

  s.add_dependency 'eventmachine'

  # For code that runs inside the EM reactor
  s.add_dependency 'em-hiredis'

  # For code that runs in a separate Ruby process
  s.add_dependency 'redis'
  s.add_dependency 'hiredis'

  s.add_dependency 'em-logger'
  s.add_dependency 'uuid'
  s.add_dependency 'oj'

  s.add_development_dependency 'rspec'

  s.files        = Dir.glob('{bin,lib}/**/*') + %w(LICENSE README.md)

  s.executables  = ['gekko']
  s.require_path = 'lib'
end
