module CrudService

  # This class provides a generic service instance for the provided DAL and logger.
  class GenericService
    attr_accessor :dal, :log

    # Instantiate a service with the specified DAL and logger.
    def initialize(dal, log)
      @dal = dal
      @log = log
    end

    # Insert a record with the supplied data record
    def insert(data)
      @dal.insert(data)
    end

    # Get all records matching the specified query
    def get_all_by_query(query)
      res = @dal.get_all_by_query(query)
      @dal.map_in_included_relations!(res,query)
      res
    end

    # Get one records matching the specified query
    def get_one_by_query(query)
      res = get_all_by_query(query)
      return nil if res.length == 0
      res[0]
    end

    # Update one record matching the specified primary key with data
    def update_by_primary_key(primary_key, data)
      @dal.update_by_primary_key(primary_key,data)
    end

    # Delete one record matching the specified primary key
    def delete_by_primary_key(primary_key)
      @dal.delete_by_primary_key(primary_key)
    end

    # Return true if a record matching the specified primary key exists
    def exists_by_primary_key?(primary_key)
      @dal.exists_by_primary_key?(primary_key)
    end

    # Return true if the specified data is valid for insert
    def valid_insert?(data)
      @dal.valid_insert?(data)
    end

    # Return true if the specified query is valid
    def valid_query?(query)
      @dal.valid_query?(query)
    end

    # Return true if the specified data is valid for update
    def valid_update?(data)
      @dal.valid_update?(data)
    end
  end
end