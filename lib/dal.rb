require 'json'
require 'mysql2'

module CrudService
  # This class creates an instance of a generic DAL (Data Access Layer) with cache 
  # capability from the provided mysql client, logger and optionally memcache client. 
  # Your should extend this class to provide configuration for your dal, please see 
  # the README file at http://github.com/tomcully/crud-service
	class Dal
    attr_accessor :mysql, :memcache, :log, :table_name, :fields, :relations, :primary_key

    # Create an instance.
    def initialize(mysql, memcache = nil, log) 
      @mysql = mysql
      @memcache = memcache
      @log = log
    end

    # Execute a Query, reading from cache if enabled.
    def cached_query(query, tables)
      unless @memcache.nil?

        unless tables.include? @table_name
          tables.push @table_name
          tables.sort!
        end

        # Get Table versions
        table_versions = ""

        tables.each do |table|
          tbversion = @memcache.get(table+"-version")
          if tbversion.nil?
            expire_table_cache([table]) 
            tbversion = 1
          end
          table_versions += table+"-"+tbversion.to_s
        end

        # Get the Query Hash
        querymd5 = "geoservice-"+Digest::MD5.hexdigest(query+":"+table_versions)

        # Read Cache and return if hit
        results = @memcache.get querymd5

        unless results.nil?
          return results 
        end

      end

      # Perform the Query
      begin
        queryresult = @mysql.query(query)
      rescue Exception => e
        @log.error("#{e}")
        return []
      end

      # Collate Results
      results = []
      unless queryresult.nil? or queryresult.count == 0
        queryresult.each do |h|
          results.push h
        end
      end

      unless @memcache.nil?
        # Write to Cache
        @memcache.set querymd5, results
      end

      # Return results
      results
    end

    # Determine if all fields and includes in the query are available
    def valid_query?(query)
      return false if query.nil?
      return true if query.keys.length == 0

      query.each_key do |k|
        return false if !@fields.has_key?(k) and k!='include' and k!='exclude'
      end

      get_includes(query).each do |k|
        return false if !@fields.has_key?(k) and !@relations.has_key?(k)
      end

      get_excludes(query).each do |k|
        return false if !@fields.has_key?(k)
      end

      true
    end

    # Build a simple where clause from the given query
    def build_where(query)
      where = ""
      query.each_pair do |k, v| 
        if (k!='include' and k!='exclude')
          where += "(`#{escape_str_field(k)}` #{build_equal_condition(v)}) AND "
        end
      end
      where.chomp(' AND ')
    end

    def build_where_ns(query,ns)
      where = ""
      query.each_pair do |k, v| 
        if (k!='include' and k!='exclude')
          where += "(`#{ns}`.`#{escape_str_field(k)}` #{build_equal_condition(v)}) AND "
        end
      end
      where.chomp(' AND ')
    end

    # Build SQL INSERT fragment from data
    def build_insert(data)
      fields = ""
      values = ""
      data.each do |k,v|
        fields += "`#{escape_str_field(k)}`, "
        values += escape_value(v)+", "
      end
      "("+fields.chomp(', ')+") VALUES ("+values.chomp(', ')+")"
    end

    # Build SQL UPDATE fragment from data
    def build_update(data)
      sql = ""
      data.each do |k,v|
        sql += "`#{escape_str_field(k)}` = "+escape_value(v)+", "
      end
      sql.chomp(", ")
    end

    # Return an escaped condition string for the value v
    def build_equal_condition(v) 
      if v.nil?
        # Nulls (nil)
        return "IS NULL"
      elsif v.kind_of? Integer or v.kind_of? Float
        # Integers / Floats
        return "= "+v.to_s
      else
        # Everything Else
        return "= '#{@mysql.escape(v.to_s)}'" 
      end
    end

    # Get fields
    def build_select_fields(fields,ns)
      select = ""
      fields.each do |k|
        select += "`#{ns}`." unless ns.nil?
        select += "`#{k}`,"
      end
      select.chomp(',')
    end

    # Get fields
    def build_fields(query)
      build_select_fields(@fields.keys - get_excludes(query),nil)
    end

    # Get fields with a namespace
    def build_fields_with_ns(query, ns)
      build_select_fields(@fields.keys - get_excludes(query),ns)
    end

    # Return an escaped SQL string for the value v
    def escape_value(v) 
      if v.nil?
        # Nulls (nil)
        return "NULL"
      elsif v.kind_of? Integer or v.kind_of? Float
        # Integers / Floats
        return v.to_s
      else
        # Everything Else
        return "'#{@mysql.escape(v.to_s)}'" 
      end
    end

    # Escape a field name
    def escape_str_field(str)
      str = str.to_s.sub(/\`/,'')
      @mysql.escape(str)
    end

    # Get one record via a query
    def get_one(query)
      res = get_all_by_query(query)
      return nil if res.length == 0
      res[0]
    end

    # Get All records via a query
    def get_all_by_query(query)
      qry = "SELECT #{build_fields(query)} FROM `#{@table_name}`"
      where = build_where(query)
      qry += " WHERE #{where}" unless where.length == 0
      cached_query(qry,[@table_name])
    end

    # Get all records for this entity and map ids to a hash
    def get_all_by_query_as_hash(query)
      map_to_hash_by_primary_key(get_all_by_query(query))
    end

    def map_in_included_relations!(result, query)
      dat = get_relation_data_as_hash(query)
      result.each do |res|
        dat.each do |name, lookup|
          res[name] = lookup[res[@relations[name][:this_key]]]
          if @relations[name][:type] == :has_one
            res[name] = res[name][0] unless res[name].nil?
          else 
            res[name] = [] if res[name].nil?
          end
        end
      end
    end

    # Get data for included relations for a query
    def get_relation_data_as_hash(query) 
      return {} if @relations.nil?

      includes = get_includes(query)

      reldata = {}

      @relations.each do |name, relation| 
        unless includes.find_index(name).nil?
          sql = get_relation_query_sql(relation, query)
          tables = get_relation_tables(relation)
          data = cached_query(sql,tables)
          reldata[name] = map_to_hash_of_arrays_by_key(data,'_table_key')
          remove_key_from_hash_of_arrays!(reldata[name],'_table_key')
        end
      end
      reldata
    end

    def remove_key_from_hash_of_arrays!(hash,key)
      hash.each do |name,arr|
        arr.each do |record|
          record.delete(key)
        end
      end
      hash
    end

    # Map a result array to a hash by primary key
    def map_to_hash_by_primary_key(result) 
      hash = {}

      result.each do |record|
        hash[record[@primary_key]] = record
      end

      hash
    end

    # Map a result array to a hash of arrays by a specific key
    def map_to_hash_of_arrays_by_key(result,key) 
      res = {}

      result.each do |record|
        res[record[key]] = [] unless res.has_key?(record[key])
        res[record[key]].push record
      end

      res
    end

    # Add a field to each record from map using another field as a key
    def add_field_from_map!(result, map, field_name, key_name)
      out = []
      result.each do |record|
        record[field_name] = map[record[key_name]] if map.has_key?(record[key_name])
      end
    end

    # Get includes
    def get_includes(query)
      return [] if query.nil? or !query.has_key?('include') or query['include'].nil?
      query['include'].split(',')
    end

    # Get excludes
    def get_excludes(query)
      return [] if query.nil? or !query.has_key?('exclude') or query['exclude'].nil?
      query['exclude'].split(',')
    end

    # Get sql to load relation
    def get_relation_query_sql(relation, query)
      case relation[:type]
      when :has_one
        return get_has_one_relation_query_sql(relation, query)
      when :has_many
        return get_has_many_relation_query_sql(relation, query)
      when :has_many_through
        return get_has_many_through_relation_query_sql(relation, query)
      else
        @log.error("Relation type #{relation[:type]} undefined!")
      end
    end

    # Get the SQL query for a has_one relation
    def get_has_one_relation_query_sql(relation, query)
      fields = build_select_fields(relation[:table_fields].split(','),'a')

      qry = "SELECT #{fields},`b`.`#{relation[:this_key]}` AS `_table_key` FROM `#{relation[:table]}` AS `a`, `#{@table_name}` AS `b` WHERE (`a`.`#{relation[:table_key]}` = `b`.`#{relation[:this_key]}`)"
      where = build_where_ns(query,'b')
      qry += " AND #{where}" unless where.length == 0
      qry
    end

    # Get the SQL query for a has_many relation
    def get_has_many_relation_query_sql(relation, query)
      fields = build_select_fields(relation[:table_fields].split(','),'a')

      qry = "SELECT #{fields},`b`.`#{relation[:this_key]}` AS `_table_key` FROM `#{relation[:table]}` AS `a`, `#{@table_name}` AS `b` WHERE (`a`.`#{relation[:table_key]}` = `b`.`#{relation[:this_key]}`)"
      where = build_where_ns(query,'b')
      qry += " AND #{where}" unless where.length == 0
      qry
    end

    # Get the SQL query for a has_many_through relation
    def get_has_many_through_relation_query_sql(relation,query)
      fields = build_select_fields(relation[:table_fields].split(','),'a')

      qry = "SELECT #{fields},`c`.`#{relation[:this_key]}` AS `_table_key` FROM `#{relation[:table]}` AS `a`, `#{relation[:link_table]}` AS `b`, `#{@table_name}` AS `c` WHERE (`a`.`#{relation[:table_key]}` = `b`.`#{relation[:link_field]}` AND `b`.`#{relation[:link_key]}` = `c`.`#{relation[:this_key]}`)"
      where = build_where_ns(query,'c')
      qry += " AND #{where}" unless where.length == 0
      qry
    end

    # Get an array of table names involved in a relation query
    def get_relation_tables(relation) 
      case relation[:type]
      when :has_one
        return [@table_name, relation[:table]].sort
      when :has_many
        return [@table_name, relation[:table]].sort
      when :has_many_through
        return [@table_name, relation[:table], relation[:link_table]].sort
      else
        throw "Unknown Relation type #{relation.type}"
      end
    end

    # Expire a table cache by incrementing the table version
    def expire_table_cache(table_names)
      return if @memcache.nil?

      table_names.each do |table_name|
        key = table_name+"-version"
        version = @memcache.get(key)
        if version.nil?
          @memcache.set(key,1,nil,{:raw=>true}) 
        else
          @memcache.incr(key, 1, nil)
        end
      end

      true
    end

    # Return true if a key exists
    def exists_by_primary_key?(primary_key)
      qry = "SELECT COUNT(*) AS `c` FROM `#{@table_name}` WHERE "+build_where({@primary_key => primary_key})
      res = cached_query(qry,[@table_name])
      res[0]['c'] != 0
    end

    # Return true if an object is valid for create
    def valid_insert?(data)
      return false if data.nil?
      return false if data.keys.length == 0

      # Required fields
      @fields.each do |k,s|
        return false if s.has_key?(:required) and s[:required] == true and !data.has_key?(k)
      end

      # Only valid fields, length checking
      data.each_key do |k|
        return false if !@fields.has_key?(k)
        return false if @fields[k].has_key?(:length) and
          !data[k].nil? and
          data[k].length > @fields[k][:length]
      end

      return true
    end

    # Return true if an object is valid for update
    def valid_update?(data)
      return false if data.nil?
      return false if data.keys.length == 0

      # Only valid fields, length checking
      data.each_key do |k|
        return false if !@fields.has_key?(k)
        return false if @fields[k].has_key?(:length) and
          !data[k].nil? and
          data[k].length > @fields[k][:length]
      end

      return true
    end

    # Create a record from data
    def insert(data)
      query = "INSERT INTO `#{@table_name}` "+build_insert(data)

      begin
        queryresult = @mysql.query(query)
      rescue Exception => e
        @log.error("#{e}")
        return false
      end

      expire_table_cache(get_all_related_tables)

      get_one({@primary_key => data[@primary_key]})
    end

    # Update a record by its primary key from data
    def update_by_primary_key(primary_key, data)
      query = "UPDATE `#{@table_name}` SET "+build_update(data)+" WHERE "+build_where({@primary_key => primary_key})

      begin
        queryresult = @mysql.query(query)
      rescue Exception => e
        @log.error("#{e}")
        return false
      end

      expire_table_cache(get_all_related_tables)

      get_one({@primary_key => primary_key})
    end

    # Delete a record by its primary key from data
    def delete_by_primary_key(primary_key)
      query = "DELETE FROM `#{@table_name}` WHERE "+build_where({@primary_key => primary_key})

      begin
        queryresult = @mysql.query(query)
      rescue Exception => e
        @log.error("#{e}")
        return false
      end

      expire_table_cache(get_all_related_tables)
      true
    end

    # Return an array of all related tables plus this table
    def get_all_related_tables
      tables = [ @table_name ]
      return tables if @relations.nil?
      @relations.each do |n,r|
        tables = tables | get_relation_tables(r)
      end
      tables.sort
    end
  end
end
