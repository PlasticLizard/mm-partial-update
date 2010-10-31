require 'rubygems'
require 'bundler/setup'
require 'rake'
require 'rake/testtask'
require File.expand_path('../lib/mm_partial_update/version', __FILE__)

Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
end

task :default => :test

desc 'Builds the gem'
task :build do
  sh "gem build mm_partial_update.gemspec"
end

desc 'Builds and installs the gem'
task :install => :build do
  sh "gem install mm_partial_update-#{MmPartialUpdate::Version}"
end

desc 'Tags version, pushes to remote, and pushes gem'
task :release => :build do
  sh "git tag v#{MmPartialUpdate::Version}"
  sh "git push origin master"
  sh "git push origin v#{MmPartialUpdate::Version}"
  sh "gem push mm_partial_update-#{MmPartialUpdate::Version}.gem"
end

