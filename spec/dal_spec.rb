require "spec_helper"

describe CrudService::Dal do
  before(:each) do
    @mock_mysql = mysql_mock
    @mock_memcache = double('Memcache')
    @mock_log = double('Log')

    @generic_dal = CrudService::Dal.new(@mock_mysql, @mock_memcache, @mock_log)
    @generic_dal.table_name = "testtable"
    @generic_dal.cache_prefix = "prefix"
  end

  describe '#initialize' do 
    it 'should inject dependencies correctly' do
      expect(@generic_dal.mysql).to eq(@mock_mysql)
      expect(@generic_dal.memcache).to eq(@mock_memcache)
      expect(@generic_dal.log).to eq(@mock_log)
    end
  end

  describe '#cached_query' do
    it 'should attempt to query the cache before the database' do

      testdata = [ { "field_one" => "one" } ]

      mock_result = mysql_result_mock(testdata)

      query = 'test invalid query'
      query_hash = "prefix-"+Digest::MD5.hexdigest(query+":testtable-1")

      expect(@mock_memcache).to receive(:get).ordered.with("prefix-testtable-version").and_return(1)
      expect(@mock_memcache).to receive(:get).ordered.with(query_hash).and_return(nil)
      expect(@mock_mysql).to receive(:query).with(query).and_return(mock_result)
      expect(@mock_memcache).to receive(:set).ordered.with(query_hash, testdata)

      expect(@generic_dal.cached_query(query,[])).to eq(testdata)
    end

    it 'should not attempt to query the database on a cache hit' do
      testdata = [ { "field_one" => "one" } ]
      query = 'test invalid query'
      query_hash = "prefix-"+Digest::MD5.hexdigest(query+":testtable-1")

      expect(@mock_memcache).to receive(:get).ordered.with("prefix-testtable-version").and_return(1)
      expect(@mock_memcache).to receive(:get).ordered.with(query_hash).and_return(testdata)
      expect(@mock_mysql).not_to receive(:query)
      expect(@mock_memcache).not_to receive(:set).ordered

      expect(@generic_dal.cached_query(query,[])).to eq(testdata)
    end

    it 'should handle zero record return' do
      memcache_null(@mock_memcache)

      query = 'test invalid query'

      expect(@mock_mysql).to receive(:query).with(query).and_return(mysql_result_mock([]))

      expect(@generic_dal.cached_query(query,[])).to eq([])
    end

    it 'should write a new table version to cache when not found' do
      testdata = [ { "field_one" => "one" } ]

      mock_result = mysql_result_mock(testdata)

      query = 'test invalid query'
      query_hash = "prefix-"+Digest::MD5.hexdigest(query+":testtable-1")

      expect(@mock_memcache).to receive(:get).ordered.with("prefix-testtable-version").and_return(nil)
      expect(@mock_memcache).to receive(:get).ordered.with("prefix-testtable-version").and_return(nil)
      expect(@mock_memcache).to receive(:set).ordered.with("prefix-testtable-version",1,nil,{:raw=>true})
      expect(@mock_memcache).to receive(:get).ordered.with(query_hash).and_return(nil)
      expect(@mock_mysql).to receive(:query).ordered.with(query).and_return(mock_result)
      expect(@mock_memcache).to receive(:set).ordered.with(query_hash, testdata)

      expect(@generic_dal.cached_query(query,[])).to eq(testdata)
    end

    it 'should miss the cache when a table version has changed' do
      testdata = [ { "field_one" => "one" } ]

      mock_result = mysql_result_mock(testdata)

      query = 'test invalid query'
      query_hash = "prefix-"+Digest::MD5.hexdigest(query+":testtable-1")

      expect(@mock_memcache).to receive(:get).ordered.with("prefix-testtable-version").and_return(1)
      expect(@mock_memcache).to receive(:get).ordered.with(query_hash).and_return(nil)
      expect(@mock_mysql).to receive(:query).with(query).and_return(mock_result)
      expect(@mock_memcache).to receive(:set).ordered.with(query_hash, testdata)

      expect(@generic_dal.cached_query(query,[])).to eq(testdata)

      query_hash = "prefix-"+Digest::MD5.hexdigest(query+":testtable-2")

      expect(@mock_memcache).to receive(:get).ordered.with("prefix-testtable-version").and_return(2)
      expect(@mock_memcache).to receive(:get).ordered.with(query_hash).and_return(nil)
      expect(@mock_mysql).to receive(:query).with(query).and_return(mock_result)
      expect(@mock_memcache).to receive(:set).ordered.with(query_hash, testdata)

      expect(@generic_dal.cached_query(query,[])).to eq(testdata)
    end

  end

  describe '#build_where' do
    it 'should return an empty string when called with no query' do
      query = { }
      expect(@generic_dal.build_where(query)).to eq ""
    end

    it 'should return a valid where clause when called with a single field query string value' do
      query = { "one" => "two" }
      expect(@generic_dal.build_where(query)).to eq "(`one` = 'two')"
    end

    it 'should return a valid where clause when called with a single field query integer value' do
      query = { "one" => 2 }
      expect(@generic_dal.build_where(query)).to eq "(`one` = 2)"
    end

    it 'should return a valid where clause when called with a single field query float value' do
      query = { "one" => 2.123 }
      expect(@generic_dal.build_where(query)).to eq "(`one` = 2.123)"
    end

    it 'should return a valid where clause when called with a multiple field query' do
      query = { "one" => "two", "three" => "four" }
      expect(@generic_dal.build_where(query)).to eq "(`one` = 'two') AND (`three` = 'four')"
    end

    it 'should return a valid where clause when called with a query with a nil value' do
      query = { "one" => "two", "three" => nil}
      expect(@generic_dal.build_where(query)).to eq "(`one` = 'two') AND (`three` IS NULL)"
    end

    it 'should escape field names' do
      query = { "on`=1; DROP TABLE countries" => "two" }
      expect(@generic_dal.build_where(query)).to eq "(`on=1; DROP TABLE countries` = 'two')"
    end

    it 'should escape field values when string based' do
      query = { "one" => "two'; DROP TABLE countries;" }
      expect(@generic_dal.build_where(query)).to eq "(`one` = 'two\\'; DROP TABLE countries;')"
    end

    it 'should not build include or exclude into queries' do
      query = { "one" => 2, "include" => "subdivisions", "exclude" => "countries", "two"=>3 }
      expect(@generic_dal.build_where(query)).to eq "(`one` = 2) AND (`two` = 3)"
    end
  end

  describe '#build_where_ns_ns' do
    it 'should return an empty string when called with no query' do
      query = { }
      expect(@generic_dal.build_where_ns(query,'a')).to eq ""
    end

    it 'should return a valid where clause when called with a single field query string value' do
      query = { "one" => "two" }
      expect(@generic_dal.build_where_ns(query,'b')).to eq "(`b`.`one` = 'two')"
    end

    it 'should return a valid where clause when called with a single field query integer value' do
      query = { "one" => 2 }
      expect(@generic_dal.build_where_ns(query,'c')).to eq "(`c`.`one` = 2)"
    end

    it 'should return a valid where clause when called with a single field query float value' do
      query = { "one" => 2.123 }
      expect(@generic_dal.build_where_ns(query,'d')).to eq "(`d`.`one` = 2.123)"
    end

    it 'should return a valid where clause when called with a multiple field query' do
      query = { "one" => "two", "three" => "four" }
      expect(@generic_dal.build_where_ns(query,'e')).to eq "(`e`.`one` = 'two') AND (`e`.`three` = 'four')"
    end

    it 'should return a valid where clause when called with a query with a nil value' do
      query = { "one" => "two", "three" => nil}
      expect(@generic_dal.build_where_ns(query,'f')).to eq "(`f`.`one` = 'two') AND (`f`.`three` IS NULL)"
    end

    it 'should escape field names' do
      query = { "on`=1; DROP TABLE countries" => "two" }
      expect(@generic_dal.build_where_ns(query,'g')).to eq "(`g`.`on=1; DROP TABLE countries` = 'two')"
    end

    it 'should escape field values when string based' do
      query = { "one" => "two'; DROP TABLE countries;" }
      expect(@generic_dal.build_where_ns(query,'h')).to eq "(`h`.`one` = 'two\\'; DROP TABLE countries;')"
    end

    it 'should not build include or exclude into queries' do
      query = { "one" => 2, "include" => "subdivisions", "exclude" => "countries", "two"=>3 }
      expect(@generic_dal.build_where_ns(query,'i')).to eq "(`i`.`one` = 2) AND (`i`.`two` = 3)"
    end
  end

  describe '#build_fields' do
    it 'should return an empty string with no fields' do
      expect(@generic_dal.build_select_fields([],nil)).to eq ""
    end

    it 'should return fields correctly' do
      expect(@generic_dal.build_select_fields(['one','two'],nil)).to eq "`one`,`two`"
    end

    it 'should return namespaced fields correctly' do
      expect(@generic_dal.build_select_fields(['one','two'],'a')).to eq "`a`.`one`,`a`.`two`"
    end
  end

  describe '#build_fields' do
    before(:each) do
      @generic_dal.fields = {
        "test1" => { :type=>:string },
        "test2" => { :type=>:string },
        "testX" => { :type=>:string },
      }
    end
    
    it 'should return all fields with nil excludes' do
      expect(@generic_dal.build_fields({})).to eq "`test1`,`test2`,`testX`"
    end

    it 'should return all fields with empty excludes' do
      expect(@generic_dal.build_fields({"exclude"=>nil})).to eq "`test1`,`test2`,`testX`"
    end

    it 'should exclude a single field' do
      expect(@generic_dal.build_fields({"exclude"=>'test1'})).to eq "`test2`,`testX`"
    end

    it 'should exclude multiple fields' do
      expect(@generic_dal.build_fields({"exclude"=>'test1,testX'})).to eq "`test2`"
    end
  end

  describe '#build_fields_with_ns' do
    before(:each) do
      @generic_dal.fields = {
        "test1" => { :type=>:string },
        "test2" => { :type=>:string },
        "testX" => { :type=>:string },
      }
    end
    
    it 'should return all fields with nil excludes' do
      expect(@generic_dal.build_fields_with_ns({},'a')).to eq "`a`.`test1`,`a`.`test2`,`a`.`testX`"
    end

    it 'should return all fields with empty excludes' do
      expect(@generic_dal.build_fields_with_ns({"exclude"=>nil},'b')).to eq "`b`.`test1`,`b`.`test2`,`b`.`testX`"
    end

    it 'should exclude a single field' do
      expect(@generic_dal.build_fields_with_ns({"exclude"=>'test1'},'c')).to eq "`c`.`test2`,`c`.`testX`"
    end

    it 'should exclude multiple fields' do
      expect(@generic_dal.build_fields_with_ns({"exclude"=>'test1,testX'},'d')).to eq "`d`.`test2`"
    end
  end

  describe '#get_includes' do
    before(:each) do
      @generic_dal.fields = ["test1", "test2", "testX"]
    end

    it 'should return an empty array with a nil query' do
      expect(@generic_dal.get_includes(nil)).to eq []
    end

    it 'should return an empty array with no fields or includes' do
      query = { }
      expect(@generic_dal.get_includes(query)).to eq []
    end

    it 'should return an empty array with fields and no includes' do
      query = { "field2" => "xxas"}
      expect(@generic_dal.get_includes(query)).to eq []
    end

    it 'should return a single include' do
      query = { "include"=>"test1" }
      expect(@generic_dal.get_includes(query)).to eq ['test1']
    end

    it 'should return multiple includes' do
      query = { "include"=>"test1,test2"}
      expect(@generic_dal.get_includes(query)).to eq ['test1','test2']
    end
  end

  describe '#get_excludes' do
    before(:each) do
      @generic_dal.fields = {
        "test1" => { :type=>:string },
        "test2" => { :type=>:string },
        "testX" => { :type=>:string },
      }
    end

    it 'should return an empty array with a nil query' do
      expect(@generic_dal.get_excludes(nil)).to eq []
    end

    it 'should return an empty array with no fields or excludes' do
      query = { }
      expect(@generic_dal.get_excludes(query)).to eq []
    end

    it 'should return an empty array with fields and no excludes' do
      query = { "field2" => "xxas"}
      expect(@generic_dal.get_excludes(query)).to eq []
    end

    it 'should return a single exclude' do
      query = { "exclude"=>"test1", "field2" => "xxas"}
      expect(@generic_dal.get_excludes(query)).to eq ['test1']
    end

    it 'should return multiple excludes' do
      query = { "exclude"=>"test1,test2"}
      expect(@generic_dal.get_excludes(query)).to eq ['test1','test2']
    end
  end

  describe '#build_equal_condition' do
    it 'should return IS NULL for a nil' do
      expect(@generic_dal.build_equal_condition(nil)).to eq 'IS NULL'
    end

    it 'should return correct response for an integer' do
      expect(@generic_dal.build_equal_condition(1)).to eq '= 1'
    end

    it 'should return correct response for a float' do
      expect(@generic_dal.build_equal_condition(1.123)).to eq '= 1.123'
    end

    it 'should return correct response for a string' do
      expect(@generic_dal.build_equal_condition('ABC')).to eq "= 'ABC'"
    end

    it 'should return correct escaped response for a string' do
      expect(@generic_dal.build_equal_condition("AB'; DROP TABLE test_table --")).to eq "= 'AB\\'; DROP TABLE test_table --'"
    end
  end

  describe '#valid_query?' do
    before(:each) do
      @generic_dal.fields = {
        "one" => { :type=>:string },
        "two" => { :type=>:string },
        "three" => { :type=>:string },
      }
      @generic_dal.relations = {
        "four" => { :type=>:string },
        "five" => { :type=>:string },
        "six" => { :type=>:string },
      }
    end
    
    it 'should return true with valid fields' do
      expect(@generic_dal.valid_query?({"one"=>1})).to be true
    end

    it 'should return false with invalid fields' do
      expect(@generic_dal.valid_query?({"five"=>1})).to be false
    end

    it 'should return true with valid relations' do
      expect(@generic_dal.valid_query?({"include"=>'four,five'})).to be true
    end

    it 'should return false with invalid relations' do
      expect(@generic_dal.valid_query?({"include"=>'ten'})).to be false
    end

    it 'should return false with nil' do
      expect(@generic_dal.valid_query?(nil)).to be false
    end

    it 'should return true with no fields' do
      expect(@generic_dal.valid_query?({})).to be true
    end

    it 'should return true regardless of include' do
      expect(@generic_dal.valid_query?({"one"=>1,"include"=>"two"})).to be true
    end

    it 'should return true regardless of exclude' do
      expect(@generic_dal.valid_query?({"one"=>1,"exclude"=>"one"})).to be true
    end

    it 'should return false as cannot exclude a relation' do
      expect(@generic_dal.valid_query?({"one"=>1,"exclude"=>"five"})).to be false
    end
  end

  describe '#escape_str_field' do
    it 'should escape single quotes' do
      expect(@generic_dal.escape_str_field("ABC'BC")).to eq "ABC\\'BC"
    end

    it 'should remove backtics' do
      expect(@generic_dal.escape_str_field("ABC`BC")).to eq "ABCBC"
    end

    it 'should resolve symbols as well as strings' do
      expect(@generic_dal.escape_str_field(:testing)).to eq "testing"
    end
  end

  describe '#get_all_by_query' do
    it 'should call cached_query with the correct query for one field' do
      memcache_null(@mock_memcache)
      @generic_dal.fields = {
        "one" => { :type=>:string },
        "two" => { :type=>:string },
      }
      @generic_dal.table_name = 'test_table'

      expect(@mock_mysql).to receive(:query).with("SELECT `one`,`two` FROM `test_table` WHERE (`field` = 'test2')")

      @generic_dal.get_all_by_query({ :field => 'test2' })
    end

    it 'should call cached_query with the correct query for multiple fields' do
      memcache_null(@mock_memcache)
      @generic_dal.fields = {
        "one" => { :type=>:string },
        "two" => { :type=>:string },
      }
      @generic_dal.table_name = 'test_table'

      expect(@mock_mysql).to receive(:query).with("SELECT `one`,`two` FROM `test_table` WHERE (`field` = 'test2') AND (`twofield` = 2) AND (`nullfield` IS NULL)")

      @generic_dal.get_all_by_query({ :field => 'test2', "twofield" =>2, "nullfield" => nil })
    end
  end

  describe '#get_last_id' do
    it 'should call mysql last_id' do
       expect(@mock_mysql).to receive(:last_id)
       @generic_dal.get_last_id
    end
  end

  describe '#get_one' do
    before(:each) do
      memcache_null(@mock_memcache)

      @generic_dal.fields = {
        "one" => { :type=>:string },
        "two" => { :type=>:string },
      }

      @generic_dal.table_name = 'test_table'

      @mock_result = mysql_result_mock([
        { "field_one" => "one" },
        { "field_one" => "two" } 
      ])
    end

    it 'should call cached_query with the correct query for one field and return a single object' do
      expect(@mock_mysql).to receive(:query)
        .with("SELECT `one`,`two` FROM `test_table` WHERE (`field` = 'test2')")
        .and_return(@mock_result)

      expect(@generic_dal.get_one({ :field => 'test2' })).to eq({ "field_one" => "one" })
    end

    it 'should call cached_query with the correct query for one field and return a single object' do
      expect(@mock_mysql).to receive(:query)
        .with("SELECT `one`,`two` FROM `test_table` WHERE (`field` = 'test2') AND (`field_two` = 'test3')")
        .and_return(@mock_result)

      expect(@generic_dal.get_one({ :field => 'test2', :field_two => 'test3' })).to eq({ "field_one" => "one" })
    end
  end

  describe '#map_to_hash_by_primary_key' do
    before(:each) do
      @generic_dal.primary_key = 'id'
    end

    it 'should return an empty hash when given an empty array' do
      test = []

      expect(@generic_dal.map_to_hash_by_primary_key(test)).to eq({})
    end

    it 'should correctly map an array' do
      test = [
        { "id" => 1, "field_one" => "one" },
        { "id" => 2.5, "field_one" => "two point five" },
        { "id" => "3", "field_one" => "three" },
        { "id" => nil, "field_one" => "four" } 
      ]

      expect(@generic_dal.map_to_hash_by_primary_key(test)).to eq({
        1 => { "id" => 1, "field_one" => "one" },
        2.5 => { "id" => 2.5, "field_one" => "two point five" },
        "3" => { "id" => "3", "field_one" => "three" },
        nil =>  { "id" => nil, "field_one" => "four" } 
      })
    end
  end

  describe '#remove_key_from_hash_of_arrays!' do
  
    it 'should remove a key from each hash in each array in each hash value' do

      test = {
        'one' => [ ],
        2 => [ {"x" => 'a', "y" => 'b', 'z' => 'c' } ],
        nil => [ {"x" => 'd', "y" => 'e', 'z' => 'f' }, {"x" => 'g', "y" => 'h', 'z' => 'i' } ],
      }

      @generic_dal.remove_key_from_hash_of_arrays!(test,'z')

      expect(test).to eq({
        'one' => [ ],
        2 => [ {"x" => 'a', "y" => 'b'} ],
        nil => [ {"x" => 'd', "y" => 'e' }, {"x" => 'g', "y" => 'h' } ],
      })

    end
  end

  describe '#map_to_hash_of_arrays_by_key' do
    it 'should return an empty hash when given an empty array' do
      test = []

      expect(@generic_dal.map_to_hash_of_arrays_by_key(test,'field_one')).to eq({})
    end

    it 'should correctly map an array' do
      test = [
        { "id" => 1, "field_one" => 1 },
        { "id" => 2.5, "field_one" => "two point five" },
        { "id" => "3", "field_one" => "three" },
        { "id" => nil, "field_one" => 4.5 }, 
        { "id" => nil, "field_one" => 1 },
        { "id" => 90, "field_one" => "two point five" },
        { "id" => nil, "field_one" => "four" },
        { "id" => "16", "field_one" => "three" },
        { "id" => 2.1, "field_one" => 4.5 },
        { "id" => 328, "field_one" => "one" },
        { "id" => nil, "field_one" => nil },
        { "id" => 123, "field_one" => nil },
      ]

      expect(@generic_dal.map_to_hash_of_arrays_by_key(test,'field_one')).to eq({
        nil => [
          { "id" => nil, "field_one" => nil },
          { "id" => 123, "field_one" => nil },
        ],
        1 => [
          { "id" => 1, "field_one" => 1 },
          { "id" => nil, "field_one" => 1 },
        ],
        "two point five" => [
          { "id" => 2.5, "field_one" => "two point five" },
          { "id" => 90, "field_one" => "two point five" },
        ],
        "three" => [
          { "id" => "3", "field_one" => "three" },
          { "id" => "16", "field_one" => "three" },
        ],
        "four" => [
          { "id" => nil, "field_one" => "four" },
        ],
        4.5 => [
          { "id" => nil, "field_one" => 4.5 },
          { "id" => 2.1, "field_one" => 4.5 },
        ],
        "one" => [
          { "id" => 328, "field_one" => "one" },
        ]
      })
    end
  end

  describe '#add_field_from_map!' do
    it 'should map correctly' do
      records = [
        {"id"=>1, "fk_code"=>"EU", "name"=>"Test1" },
        {"id"=>2, "fk_code"=>"EU", "name"=>"Test2" },
        {"id"=>3, "fk_code"=>"AU", "name"=>"Test3" },
        {"id"=>4, "fk_code"=>"GB", "name"=>"Test4" },
        {"id"=>5, "fk_code"=>"US", "name"=>"Test5" },
        {"id"=>6, "fk_code"=>nil, "name"=>"Test5" },
      ]

      map = {
        'EU' => 1,
        'AU' => { "name"=>"one" },
        'US' => nil,
        'GB' => "test!"
      }

      @generic_dal.add_field_from_map!(records, map, 'fk_field', 'fk_code')

      expect(records).to eq [
        {"id"=>1, "fk_code"=>"EU", "name"=>"Test1", "fk_field"=>1 },
        {"id"=>2, "fk_code"=>"EU", "name"=>"Test2", "fk_field"=>1 },
        {"id"=>3, "fk_code"=>"AU", "name"=>"Test3", "fk_field"=>{ "name"=>"one" } },
        {"id"=>4, "fk_code"=>"GB", "name"=>"Test4", "fk_field"=>"test!" },
        {"id"=>5, "fk_code"=>"US", "name"=>"Test5", "fk_field"=>nil },
        {"id"=>6, "fk_code"=>nil, "name"=>"Test5" },
      ]

    end
  end

  describe '#get_relation_query_sql' do
    it 'should return the correct sql for a has_one relation with no query' do

      @generic_dal.table_name = "currencies"

      rel = { 
        :type         => :has_one, 
        :table        => 'countries',
        :table_key    => 'default_currency_code', 
        :this_key     => 'code',
        :table_fields => 'code_alpha_2,name',
      }

      expect(@generic_dal.get_relation_query_sql(rel,{})).to eq(
        "SELECT `a`.`code_alpha_2`,`a`.`name`,`b`.`code` AS `_table_key` FROM `countries` AS `a`, `currencies` AS `b` WHERE (`a`.`default_currency_code` = `b`.`code`)"
      )
      
    end

    it 'should return the correct sql for a has_one relation with a query' do

      @generic_dal.table_name = "currencies"

      rel = { 
        :type         => :has_one, 
        :table        => 'countries',
        :table_key    => 'default_currency_code', 
        :this_key     => 'code',
        :table_fields => 'code_alpha_2,name',
      }

      expect(@generic_dal.get_relation_query_sql(rel,{'testfield'=>1})).to eq(
        "SELECT `a`.`code_alpha_2`,`a`.`name`,`b`.`code` AS `_table_key` FROM `countries` AS `a`, `currencies` AS `b` WHERE (`a`.`default_currency_code` = `b`.`code`) AND (`b`.`testfield` = 1)"
      )
      
    end

    it 'should return the correct sql for a has_many relation' do

      @generic_dal.table_name = "houses"

      rel = { 
        :type         => :has_many,
        :table        => 'cats',
        :table_key    => 'house_id', 
        :this_key     => 'id',
        :table_fields => 'cat_id,name',
      }

      expect(@generic_dal.get_relation_query_sql(rel,{})).to eq(
        "SELECT `a`.`cat_id`,`a`.`name`,`b`.`id` AS `_table_key` FROM `cats` AS `a`, `houses` AS `b` WHERE (`a`.`house_id` = `b`.`id`)"
      )
      
    end

    it 'should return the correct sql for a has_many relation with a query' do

      @generic_dal.table_name = "houses"

      rel = { 
        :type         => :has_many,
        :table        => 'cats',
        :table_key    => 'house_id', 
        :this_key     => 'id',
        :table_fields => 'cat_id,name',
      }

      expect(@generic_dal.get_relation_query_sql(rel,{"colour"=>"ginger"})).to eq(
        "SELECT `a`.`cat_id`,`a`.`name`,`b`.`id` AS `_table_key` FROM `cats` AS `a`, `houses` AS `b` WHERE (`a`.`house_id` = `b`.`id`) AND (`b`.`colour` = 'ginger')"
      )
      
    end

    it 'should return the correct sql for a has_many_through relation' do

      @generic_dal.table_name = "countries"

      rel = { 
        :type         => :has_many_through,
        :table        => 'regions',
        :link_table   => 'region_countries',
        :link_key     => 'country_code_alpha_2',
        :link_field   => 'region_code',
        :table_key    => 'code', 
        :this_key     => 'code_alpha_2',
        :table_fields => 'code,name',
      }

      expect(@generic_dal.get_relation_query_sql(rel,{})).to eq(
        "SELECT `a`.`code`,`a`.`name`,`c`.`code_alpha_2` AS `_table_key` FROM `regions` AS `a`, `region_countries` AS `b`, `countries` AS `c` WHERE (`a`.`code` = `b`.`region_code` AND `b`.`country_code_alpha_2` = `c`.`code_alpha_2`)"
      )
      
    end

    it 'should return the correct sql for a has_many_through relation with a query' do

      @generic_dal.table_name = "countries"

      rel = { 
        :type         => :has_many_through,
        :table        => 'regions',
        :link_table   => 'region_countries',
        :link_key     => 'country_code_alpha_2',
        :link_field   => 'region_code',
        :table_key    => 'code', 
        :this_key     => 'code_alpha_2',
        :table_fields => 'code,name',
      }

      expect(@generic_dal.get_relation_query_sql(rel,{"default_currency_code"=>"EUR"})).to eq(
        "SELECT `a`.`code`,`a`.`name`,`c`.`code_alpha_2` AS `_table_key` FROM `regions` AS `a`, `region_countries` AS `b`, `countries` AS `c` WHERE (`a`.`code` = `b`.`region_code` AND `b`.`country_code_alpha_2` = `c`.`code_alpha_2`) AND (`c`.`default_currency_code` = 'EUR')"
      )
      
    end
  end

  describe "#get_relation_tables" do
    it 'should return the correct tables for a has_one relation' do
      @generic_dal.table_name = "currencies"

      rel = { 
        :type         => :has_one, 
        :table        => 'countries',
        :table_key    => 'default_currency_code', 
        :this_key     => 'code',
        :table_fields => 'code_alpha_2,name',
      }

      expect(@generic_dal.get_relation_tables(rel)).to eq(["countries", "currencies"])
    end

    it 'should return the correct tables for a has_many relation' do
      @generic_dal.table_name = "houses"

      rel = { 
        :type         => :has_many,
        :table        => 'cats',
        :table_key    => 'house_id', 
        :this_key     => 'id',
        :table_fields => 'cat_id,name',
      }

      expect(@generic_dal.get_relation_tables(rel)).to eq(["cats", "houses"])
    end

    it 'should return the correct tables for a has_many_through relation' do
      @generic_dal.table_name = "countries"

      rel = { 
        :type         => :has_many_through,
        :table        => 'regions',
        :link_table   => 'region_countries',
        :link_key     => 'country_code_alpha_2',
        :link_field   => 'region_code',
        :table_key    => 'code', 
        :this_key     => 'code_alpha_2',
        :table_fields => 'code,name',
      }

      expect(@generic_dal.get_relation_tables(rel)).to eq(["countries","region_countries","regions"])
    end
  end

  describe '#expire_table_cache' do
    it 'should set a table version when it doesnt exist' do

      expect(@mock_memcache).to receive(:get).ordered.with("prefix-testtable-version").and_return(nil)
      expect(@mock_memcache).to receive(:set).ordered.with("prefix-testtable-version",1,nil,{:raw=>true}).and_return(nil)

      @generic_dal.expire_table_cache(['testtable'])
    end

    it 'should increment a table version when it exists' do

      expect(@mock_memcache).to receive(:get).ordered.with("prefix-testtable-version").and_return(1)
      expect(@mock_memcache).to receive(:incr).ordered.with("prefix-testtable-version",1,nil).and_return(nil)

      @generic_dal.expire_table_cache(['testtable'])
    end

    it 'should expire multiple tables' do

      expect(@mock_memcache).to receive(:get).ordered.with("prefix-testtable-version").and_return(1)
      expect(@mock_memcache).to receive(:incr).ordered.with("prefix-testtable-version",1,nil).and_return(nil)
      expect(@mock_memcache).to receive(:get).ordered.with("prefix-tabletwo-version").and_return(1)
      expect(@mock_memcache).to receive(:incr).ordered.with("prefix-tabletwo-version",1,nil).and_return(nil)

      @generic_dal.expire_table_cache(['testtable','tabletwo'])
    end
  end

  describe '#exists_by_primary_key?' do
    before do
      memcache_null(@mock_memcache)

      @generic_dal.table_name = 'pktesttable'
      @generic_dal.primary_key = 'id'

      @mock_result = mysql_result_mock([ { "c" => 1 } ])
    end

    it 'should call cached_query with correct sql with a numeric primary key' do
      expect(@mock_mysql).to receive(:query).with("SELECT COUNT(*) AS `c` FROM `pktesttable` WHERE (`id` = 2002)").and_return(@mock_result)

      expect(@generic_dal.exists_by_primary_key?(2002)).to eq(true)
    end

    it 'should call cached_query with correct sql with a string primary key' do
      expect(@mock_mysql).to receive(:query).with("SELECT COUNT(*) AS `c` FROM `pktesttable` WHERE (`id` = 'test')").and_return(@mock_result)

      expect(@generic_dal.exists_by_primary_key?('test')).to eq(true)
    end

    it 'should return true when count is not 0' do
      @mock_result = mysql_result_mock([ { "c" => 1 } ])

      expect(@mock_mysql).to receive(:query).with("SELECT COUNT(*) AS `c` FROM `pktesttable` WHERE (`id` = 'test')").and_return(@mock_result)

      expect(@generic_dal.exists_by_primary_key?('test')).to eq(true)
    end

    it 'should return false when count is 0' do
      @mock_result = mysql_result_mock([ { "c" => 0 } ])

      expect(@mock_mysql).to receive(:query).with("SELECT COUNT(*) AS `c` FROM `pktesttable` WHERE (`id` = 'test')").and_return(@mock_result)

      expect(@generic_dal.exists_by_primary_key?('test')).to eq(false)
    end
  end

  describe '#valid_insert?' do
    it 'should return false if object nil' do
      expect(@generic_dal.valid_insert?(nil)).to eq(false)
    end

    it 'should return false if object empty' do
      expect(@generic_dal.valid_insert?({})).to eq(false)
    end

    it 'should return true if all fields exist' do
      @generic_dal.fields = {
        "one" => { :type=>:string },
        "two" => { :type=>:string },
      }

      expect(@generic_dal.valid_insert?({ "one"=>"1", "two"=>"2" })).to eq(true)
    end

    it 'should return false if fields do not exist' do
      @generic_dal.fields = {
        "one" => { :type=>:string },
        "two" => { :type=>:string },
      }

      expect(@generic_dal.valid_insert?({ "five"=>"1", "two"=>"2" })).to eq(false)
    end

    it 'should return true if data is within the max length' do
      @generic_dal.fields = {
        "one" => { :type=>:string },
        "two" => { :type=>:string, :length=>4 },
      }

      expect(@generic_dal.valid_insert?({ "one"=>"1", "two"=>"2" })).to eq(true)
    end

    it 'should return false if data is greater than the max length' do
      @generic_dal.fields = {
        "one" => { :type=>:string },
        "two" => { :type=>:string, :length=>4 },
      }

      expect(@generic_dal.valid_insert?({ "one"=>"1", "two"=>"22332" })).to eq(false)
    end

    it 'should return false if required key is missing' do
      @generic_dal.fields = {
        "one" => { :type=>:string },
        "two" => { :type=>:string, :required=>true },
      }

      expect(@generic_dal.valid_insert?({ "one"=>"1" })).to eq(false)
    end

    it 'should return true if required keys are ok' do
      @generic_dal.fields = {
        "one" => { :type=>:string, :required=>true  },
        "two" => { :type=>:string, :required=>true },
      }

      expect(@generic_dal.valid_insert?({ "one"=>"1","two"=>"2" })).to eq(true)
    end
  end

  describe '#valid_update?' do
    it 'should return false if object nil' do
      expect(@generic_dal.valid_update?(nil)).to eq(false)
    end

    it 'should return false if object empty' do
      expect(@generic_dal.valid_update?({})).to eq(false)
    end

    it 'should return true if all fields exist' do
      @generic_dal.fields = {
        "one" => { :type=>:string },
        "two" => { :type=>:string },
      }

      expect(@generic_dal.valid_update?({ "one"=>"1", "two"=>"2" })).to eq(true)
    end

    it 'should return false if fields do not exist' do
      @generic_dal.fields = {
        "one" => { :type=>:string },
        "two" => { :type=>:string },
      }

      expect(@generic_dal.valid_update?({ "five"=>"1", "two"=>"2" })).to eq(false)
    end

    it 'should return false if data is greater than the max length' do
      @generic_dal.fields = {
        "one" => { :type=>:string },
        "two" => { :type=>:string, :length=>4 },
      }

      expect(@generic_dal.valid_update?({ "one"=>"1", "two"=>"22332" })).to eq(false)
    end
  end

  describe "#escape_value" do
    it 'should return NULL for nil' do
      expect(@generic_dal.escape_value(nil)).to eq('NULL')
    end

    it 'should return integer for int/float' do
      expect(@generic_dal.escape_value(1)).to eq('1')
      expect(@generic_dal.escape_value(1.45)).to eq('1.45')
    end

    it 'should return a quoted string for string' do
      expect(@generic_dal.escape_value('test')).to eq("'test'")
    end

    it 'should escape sql values properly' do
      expect(@generic_dal.escape_value("test '; DROP TABLE test; --")).to eq("'test \\'; DROP TABLE test; --'")
    end
  end

  describe "#build_insert" do
    it 'should return correct SQL fragment for basic fields' do
      data = {
        "one" => 1,
        "two" => "2",
        "three" => nil,
      }

      expect(@generic_dal.build_insert(data)).to eq("(`one`, `two`, `three`) VALUES (1, '2', NULL)")
    end

    it 'should escape field names and data' do
      data = {
        "one`; DROP TABLE test; -- " => 1,
        "two" => "two",
        "three" => "'; DROP TABLE test; --'",
      }

      expect(@generic_dal.build_insert(data)).to eq("(`one; DROP TABLE test; -- `, `two`, `three`) VALUES (1, 'two', '\\'; DROP TABLE test; --\\'')")
    end
  end

  describe "#build_update" do
    it 'should return correct SQL fragment for basic fields' do
      data = {
        "one" => 1,
        "two" => "two",
        "three" => nil,
      }

      expect(@generic_dal.build_update(data)).to eq("`one` = 1, `two` = 'two', `three` = NULL")
    end

    it 'should escape field names and data' do
      data = {
        "one`; DROP TABLE test; -- " => 1,
        "two" => "2",
        "three" => "'; DROP TABLE test; --'",
      }

      expect(@generic_dal.build_update(data)).to eq("`one; DROP TABLE test; -- ` = 1, `two` = '2', `three` = '\\'; DROP TABLE test; --\\''")
    end
  end

  describe "#get_all_related_tables" do
    it 'should return the table name for nil relations' do
      @generic_dal.table_name = 'test1'

      @generic_dal.relations = nil

      expect(@generic_dal.get_all_related_tables).to eq(["test1"])
    end

    it 'should return the table name for empty relations' do
      @generic_dal.table_name = 'test1'

      @generic_dal.relations = {}

      expect(@generic_dal.get_all_related_tables).to eq(["test1"])
    end

    it 'should return the table name for a single relations' do
      @generic_dal.table_name = 'test1'

       @generic_dal.relations = {
        'countries' => { 
          :type         => :has_one, 
          :table        => 'countries',
          :table_key    => 'default_currency_code', 
          :this_key     => 'code',
          :table_fields => 'code_alpha_2,name',
        },
      }

      expect(@generic_dal.get_all_related_tables).to eq(["countries","test1"])
    end


    it 'should return the correct table names for multiple relations with dedupe' do
      @generic_dal.table_name = 'test1'

      @generic_dal.relations = {
        'countries' => { 
          :type         => :has_one, 
          :table        => 'countries',
          :table_key    => 'default_currency_code', 
          :this_key     => 'code',
          :table_fields => 'code_alpha_2,name',
        },
        'countries2' => { 
          :type         => :has_many, 
          :table        => 'countries',
          :table_key    => 'default_currency_code', 
          :this_key     => 'code',
          :table_fields => 'code_alpha_2,name',
        },
        'regions' => { 
          :type         => :has_many_through,
          :table        => 'regions',
          :link_table   => 'region_countries',
          :link_key     => 'country_code_alpha_2',
          :link_field   => 'region_code',
          :table_key    => 'code', 
          :this_key     => 'code_alpha_2',
          :table_fields => 'code,name',
        }
      }

      expect(@generic_dal.get_all_related_tables).to eq(["countries", "region_countries", "regions", "test1"])
    end
  end

  describe '#insert' do
    it 'should call the correct sql and expire the correct cache' do
      testdata = { "field_one" => "one" }

      @generic_dal.table_name = "test_table"
      @generic_dal.fields = {
        "field_one" => { :type => :integer }
      }
      @generic_dal.auto_primary_key = false

      query = "INSERT INTO `test_table` (`field_one`) VALUES ('one')"

      expect(@mock_mysql).to receive(:query).ordered.with(query)
      expect(@mock_mysql).not_to receive(:last_id)

      expect(@mock_memcache).to receive(:get).ordered.with('prefix-test_table-version').and_return(1)
      expect(@mock_memcache).to receive(:incr).ordered.with('prefix-test_table-version',1,nil)
      
      expect(@mock_memcache).to receive(:get).ordered.with('prefix-test_table-version').and_return(1)
      expect(@mock_memcache).to receive(:get).ordered.and_return([{ "field_one" => "one","id"=>1 }])
            
      @generic_dal.insert(testdata)
    end

    it 'should call last_id when auto_primary_key is true' do
      testdata = { "field_one" => "one" }

      @generic_dal.table_name = "test_table"
      @generic_dal.fields = {
        "field_one" => { :type => :integer }
      }
      @generic_dal.auto_primary_key = true

      query = "INSERT INTO `test_table` (`field_one`) VALUES ('one')"

      expect(@mock_mysql).to receive(:query).ordered.with(query)
      expect(@mock_mysql).to receive(:last_id)

      expect(@mock_memcache).to receive(:get).ordered.with('prefix-test_table-version').and_return(1)
      expect(@mock_memcache).to receive(:incr).ordered.with('prefix-test_table-version',1,nil)
      
      expect(@mock_memcache).to receive(:get).ordered.with('prefix-test_table-version').and_return(1)
      expect(@mock_memcache).to receive(:get).ordered.and_return([{ "field_one" => "one","id"=>1 }])
      expect(@mock_memcache).not_to receive(:last_id)

      @generic_dal.insert(testdata)
    end
  end

  describe '#update_by_primary_key' do
    it 'should call the correct sql and expire the correct cache' do
      testdata = { "field_one" => "two" }

      @generic_dal.table_name = "test_table"
      @generic_dal.primary_key = "code"
      @generic_dal.fields = {
        "field_one" => { :type => :integer }
      }

      query = "UPDATE `test_table` SET `field_one` = 'two' WHERE (`code` = 2)"

      expect(@mock_mysql).to receive(:query).ordered.with(query)
      
      expect(@mock_memcache).to receive(:get).ordered.with('prefix-test_table-version').and_return(1)
      expect(@mock_memcache).to receive(:incr).ordered.with('prefix-test_table-version',1,nil)
      
      expect(@mock_memcache).to receive(:get).ordered.with('prefix-test_table-version').and_return(1)
      expect(@mock_memcache).to receive(:get).ordered.and_return([{ "field_one" => "two","id"=>2}])
      
      @generic_dal.update_by_primary_key(2, testdata)
    end
  end

  describe '#delete_by_primary_key' do
    it 'should call the correct sql and expire the correct cache' do

      @generic_dal.table_name = "test_table"
      @generic_dal.primary_key = "code"

      query = "DELETE FROM `test_table` WHERE (`code` = 'three')"

      expect(@mock_mysql).to receive(:query).ordered.with(query)
      expect(@mock_memcache).to receive(:get).ordered.with('prefix-test_table-version').and_return(1)
      expect(@mock_memcache).to receive(:incr).ordered.with('prefix-test_table-version',1,nil)
      
      @generic_dal.delete_by_primary_key('three')
    end
  end

end
