require "dotenv"
Dotenv.load

module Helpers
  def mysql_mock
    mysql = double("Mysql2")
    mysql.stub(:escape) do |s|
      Mysql2::Client.escape(s)
    end
    mysql
  end

  # Mock a Mysql Result object that returns each_hash
  def mysql_result_mock(data)
    result = double(result)
    mock = result.stub(:each)

    data.each do |hash|
      mock = mock.and_yield(hash)
    end

    result.stub(:count).and_return(data.length)

    result
  end

  # Make the supplied memcache_mock null (no hits, null write)
  def memcache_null(memcache_mock)
    @mock_memcache.stub(:get).and_return(nil)
    @mock_memcache.stub(:set).and_return(nil)
    @mock_memcache.stub(:incr).and_return(nil)
  end
end

RSpec.configure do |c|
  c.include Helpers
end

require "coveralls"
Coveralls.wear!
SimpleCov.coverage_dir('spec/coverage')

require "crud-service"

