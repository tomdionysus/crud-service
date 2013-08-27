Gem::Specification.new do |s|
  s.name        = 'crud-service'
  s.version     = '0.0.6'
  s.date        = '2013-08-26'
  s.summary     = "A Sinatra/MySQL/Memcache CRUD Service Library"
  s.description = "A basic library for automatic CRUD services using only Sinatra, MySQL and Memcache"
  s.authors     = ["Tom Cully", "Sasha Gerrand"]
  s.email       = ['tomhughcully@gmail.com', 'rubygems-crud-service@sgerrand.com']
  s.files       = Dir.glob('lib/**/*.rb')
  s.test_files  = Dir.glob('spec/**/*.rb')
  s.homepage    = 'http://github.com/tomcully/crud-service'
  s.license     = 'Apache2'
  s.required_ruby_version = '>= 1.9.2'
  s.add_development_dependency "coveralls"
  s.add_development_dependency "dotenv"
  s.add_development_dependency "rake"
  s.add_development_dependency "rspec"
  s.add_development_dependency "rspec-mocks"
  s.add_development_dependency "rack-test"
  s.add_runtime_dependency 'dalli', '~> 2.6.4', '>= 2.6.4'
  s.add_runtime_dependency 'json', '~> 1.8.0', '>= 1.8.0'
  s.add_runtime_dependency 'mysql2', '~> 0.3.13', '>= 0.3.13'
  s.add_runtime_dependency 'sinatra', '~> 1.4.3', '>= 1.4.3'
end
