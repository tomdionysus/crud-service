files = [
  'version',
  'api',
  'dal',
  'service',
].each { |file| require "#{File.dirname(__FILE__)}/crud-service/#{file}" }