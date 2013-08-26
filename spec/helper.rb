require "coveralls"
Coveralls.wear!
require "dotenv"
Dotenv.load

require "crud-service"

RSpec.configure do |c|
  c.include Helpers
end
