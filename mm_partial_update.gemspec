# encoding: UTF-8
require File.expand_path('../lib/mm_partial_update/version', __FILE__)

Gem::Specification.new do |s|
  s.name = 'mm_partial_update'
  s.homepage = 'http://github.com/PlasticLizard/mm_partial_update'
  s.summary = 'Partial updates for MongoMapper'
  s.require_path = 'lib'
  s.authors = ['Nathan Stults']
  s.email = ['hereiam@sonic.net']
  s.version = MmPartialUpdate::Version
  s.platform = Gem::Platform::RUBY
  s.files = Dir.glob("{lib,test}/**/*") + %w[LICENSE README.rdoc]

  s.add_dependency  'observables', '~> 0.1.2'
  s.add_dependency  'mm_dirtier', '~> 0.1.0' 

  s.add_development_dependency 'rake'
  s.add_development_dependency 'log_buddy'
  s.add_development_dependency 'jnunemaker-matchy', '~> 0.4.0'
  s.add_development_dependency 'shoulda',           '~> 2.11'
end

