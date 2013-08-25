module CrudService
  class GenericApi

    def self.crud_api(sinatra, service_name, name, primary_key_name)

      sinatra.options '/'+name do
        204
      end

      sinatra.post '/'+name do
        # Get The data
        begin
          data = JSON.parse(request.body.read)
        rescue Exception => e
          return 400
        end

        # Valid POST?
        return 400 unless settings.send(service_name).valid_insert?(data)

        # Already Exists?
        return 409 if settings.send(service_name).exists_by_primary_key?(data['code'])

        # Do Insert
        record = settings.send(service_name).insert(data)

        # Other Error
        return 500 if record == false

        # Output new record
        JSON.fast_generate record
      end

      sinatra.get '/'+name do
        sanitize_params(params)
        # Check query validity
        return 400 unless settings.send(service_name).valid_query?(params)

        # Return Regions on Query
        JSON.fast_generate settings.send(service_name).get_all_by_query(params)
      end

      sinatra.get '/'+name+'/:'+primary_key_name do
        sanitize_params(params)
        return 400 unless settings.send(service_name).valid_query?(params)

        record = settings.send(service_name).get_one_by_query(params)
        return 404 if record.nil?
        JSON.fast_generate record
      end

      sinatra.put '/'+name+'/:'+primary_key_name do
        # Must Exist
        return 404 unless settings.send(service_name).exists_by_primary_key?(params[:code])
        
        # Get The Data
        begin
          data = JSON.parse(request.body.read)
        rescue Exception => e
          return 400
        end

        # Valid Update?
        return 400 unless settings.send(service_name).valid_update?(data)
        
        # Do Update
        record = settings.send(service_name).update_by_primary_key(params[:code],data)

        # Other Error
        return 500 if record.nil?

        # Return new Region
        JSON.fast_generate record
      end

      sinatra.delete '/'+name+'/:'+primary_key_name do
        # Must Exist
        return 404 unless settings.send(service_name).exists_by_primary_key?(params[:code])

        # Do Delete
        return 400 unless settings.send(service_name).delete_by_primary_key(params[:code])

        204
      end
    end
  end
end