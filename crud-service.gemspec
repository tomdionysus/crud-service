Gem::Specification.new do |s|
  s.name        = 'crud-service'
  s.version     = '0.0.5'
  s.date        = '2013-08-26'
  s.summary     = "A Sinatra/MySQL/Memcache CRUD Service Library"
  s.description = "A basic gem for automatic CRUD services using only Sinatra, MySQL and Memcache"
  s.authors     = ["Tom Cully"]
  s.email       = 'tomhughcully@gmail.com'
  s.files       = [
    "lib/crud-service.rb",
    "lib/generic_api.rb",
    "lib/generic_dal.rb",
    "lib/generic_log.rb",
    "lib/generic_service.rb",
  ]
  s.homepage    = 'http://github.com/tomcully/crud-service'
  s.license     = 'Apache2'
  s.required_ruby_version = '>= 1.9.3'

  s.add_runtime_dependency 'json', '~> 1.8.0', '>= 1.8.0'
  s.add_runtime_dependency 'sinatra', '~> 1.4.3', '>= 1.4.3'
  s.add_runtime_dependency 'dalli', '~> 2.6.4', '>= 2.6.4'
  s.add_runtime_dependency 'mysql2', '~> 0.3.13', '>= 0.3.13'
end