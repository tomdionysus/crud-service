require "coveralls"
Coveralls.wear!
SimpleCov.coverage_dir('spec/coverage')

require "dotenv"
Dotenv.load

require "crud-service"

RSpec.configure do |c|
  c.include Helpers
end
