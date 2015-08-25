require "bundler/gem_tasks"
require 'rspec/core/rake_task'
require 'rdoc/task'

RDoc::Task.new do |rd|
  rd.main = "README.rdoc"
  rd.rdoc_files.include("README.md", "lib/**/*.rb")
  rd.rdoc_dir = "doc"
end

RSpec::Core::RakeTask.new

# Provide a discoverable entry
task :test => :spec

# Travis CI: accept no substitute
task :default => :spec
