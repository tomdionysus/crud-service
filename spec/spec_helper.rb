require "dotenv"
Dotenv.load

module Helpers
  def mysql_mock
    mysql = double("Mysql2")
    allow(mysql).to receive(:escape) do |s|
      Mysql2::Client.escape(s)
    end
    mysql
  end

  # Mock a Mysql Result object that returns each_hash
  def mysql_result_mock(data)
    result = double("Result")

    allow(result).to receive(:each) { |&block|
      data.each { |item| block.call(item) }
    }

    allow(result).to receive(:count).and_return(data.length)

    result
  end

  # Make the supplied memcache_mock null (no hits, null write)
  def memcache_null(memcache_mock)
    allow(@mock_memcache).to receive(:get).and_return(nil)
    allow(@mock_memcache).to receive(:set).and_return(nil)
    allow(@mock_memcache).to receive(:incr).and_return(nil)
  end
end

RSpec.configure do |c|
  c.include Helpers
end

# Supress Warnings
warn_level = $VERBOSE
$VERBOSE = nil

if ENV.has_key?('SIMPLECOV')
  require 'simplecov'
  require 'simplecov-rcov'

  SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter
  SimpleCov.start do
    add_filter '/spec/'
  end
else
  require 'coveralls'
  Coveralls.wear!
end

require 'crud-service'

