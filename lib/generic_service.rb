module Service
  class GenericService

    attr_accessor :dal, :log

    def initialize(dal, log)
      @dal = dal
      @log = log
    end

    # CRUD

    def insert(body)
      @dal.insert(body)
    end

    def get_all_by_query(query)
      res = @dal.get_all_by_query(query)
      @dal.map_in_included_relations!(res,query)
      res
    end

    def get_one_by_query(query)
      res = get_all_by_query(query)
      return nil if res.length == 0
      res[0]
    end

    def update_by_primary_key(primary_key,body)
      @dal.update_by_primary_key(primary_key,body)
    end

    def delete_by_primary_key(primary_key)
      @dal.delete_by_primary_key(primary_key)
    end

    # Existence

    def exists_by_primary_key?(primary_key)
      @dal.exists_by_primary_key?(primary_key)
    end

    # Validation

    def valid_insert?(body)
      @dal.valid_insert?(body)
    end

    def valid_query?(query)
      @dal.valid_query?(query)
    end

    def valid_update?(body)
      @dal.valid_update?(body)
    end
  end
end