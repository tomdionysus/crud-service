Gem::Specification.new do |s|
  s.name        = 'crud-service'
  s.version     = '0.0.3'
  s.date        = '2013-08-25'
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
  s.homepage    = 'http://rubygems.org/gems/crud-service'
  s.license     = 'Apache2'
end