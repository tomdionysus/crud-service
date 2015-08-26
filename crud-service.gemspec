# -*- encoding: utf-8 -*-
require File.expand_path('../lib/crud-service/version', __FILE__)

Gem::Specification.new do |s|
  s.authors     = ["Tom Cully", "Sasha Gerrand"]
  s.email       = ['tomhughcully@gmail.com', 'rubygems-crud-service@sgerrand.com']
  s.name        = 'crud-service'
  s.version     = CrudService::VERSION
  s.date        = '2015-08-25'
  s.summary     = "A Sinatra/MySQL/Memcache CRUD Service Library"

  s.description = "A basic library for automatic CRUD services using only Sinatra, MySQL and Memcache"
  s.files       = Dir.glob('lib/**/*.rb')
  s.test_files  = Dir.glob('spec/**/*.rb')
  s.homepage    = 'http://github.com/tomcully/crud-service'
  s.license     = 'Apache2'
  s.required_ruby_version = '>= 2.1.0'

  s.add_runtime_dependency 'dalli', '~> 2.7'
  s.add_runtime_dependency 'mysql2', '~> 0.3'
  s.add_runtime_dependency 'sinatra', '~> 1.4'

  s.add_development_dependency "coveralls", '~> 0.8'
  s.add_development_dependency "dotenv", '~> 2.0'
  s.add_development_dependency "rake", "~> 10.0"
  s.add_development_dependency "rspec", '~> 3.1'
  s.add_development_dependency "rspec-mocks", '~> 3.1'
  s.add_development_dependency "rack-test", '~> 0.6'
end
