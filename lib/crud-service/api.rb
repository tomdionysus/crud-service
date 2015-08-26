module CrudService
  # This mixin provides a static methods to configure a sinatra class with the
  # provided resource name, service and api_options
  module Api
    # Set up full CRUD API functionality on the given resource
    def crud_api(resource_name, service_name, primary_key_name, api_options = {})
      api_options = get_defaults(api_options)

      crud_options(resource_name, api_options) if api_options[:enable_options]

      if api_options[:enable_write]
        crud_post(resource_name, service_name, primary_key_name, api_options) if api_options[:enable_post]
        crud_put(resource_name, service_name, primary_key_name, api_options)  if api_options[:enable_put]
        crud_delete(resource_name, service_name, primary_key_name, api_options) if api_options[:enable_delete]
      end

      if api_options[:enable_read]
        crud_get(resource_name, service_name, primary_key_name, api_options) if api_options[:enable_get]
        crud_get_all(resource_name, service_name, api_options) if api_options[:enable_get_all]
      end
    end

    # Set up OPTIONS functionality on the given resource
    def crud_options(resource_name, api_options = {})
      api_options = get_defaults(api_options)
      options '/'+resource_name do
        204
      end
    end

    # Set up UPDATE/put functionality on the given resource
    def crud_put(resource_name, service_name, primary_key_name, api_options = {})
      api_options = get_defaults(api_options)
      put '/'+resource_name+'/:'+primary_key_name do
        service = settings.send(service_name)

        # Must Exist
        return 404 unless service.exists_by_primary_key?(params[primary_key_name.to_sym])

        # Get The Data
        begin
          data = JSON.parse(request.body.read)
        rescue Exception => e
          return 422
        end

        # Valid Update?
        return 422 unless service.valid_update?(data)

        # Do Update
        record = service.update_by_primary_key(params[primary_key_name.to_sym],data)

        # Other Error
        return 500 if record.nil?

        # Return new Region
        JSON.fast_generate record
      end
    end

    # Set up GET/get_one functionality on the given resource
    def crud_get(resource_name, service_name, primary_key_name, api_options = {})
      api_options = get_defaults(api_options)
      get '/'+resource_name+'/:'+primary_key_name do
        service = settings.send(service_name)

        sanitize_params(params)
        return 400 unless service.valid_query?(params)

        record = service.get_one_by_query(params)
        return 404 if record.nil?
        JSON.fast_generate record
      end
    end

    # Set up GET/get_all functionality on the given resource
    def crud_get_all(resource_name, service_name, api_options = {})
      api_options = get_defaults(api_options)
      get '/'+resource_name do
        service = settings.send(service_name)

        sanitize_params(params)
        # Check query validity
        return 400 unless service.valid_query?(params)

        # Return Regions on Query
        JSON.fast_generate service.get_all_by_query(params)
      end
    end

    # Set up DELETE functionality on the given resource
    def crud_delete(resource_name, service_name, primary_key_name, api_options = {})
      api_options = get_defaults(api_options)
      delete '/'+resource_name+'/:'+primary_key_name do
        service = settings.send(service_name)

        # Must Exist
        return 404 unless service.exists_by_primary_key?(params[primary_key_name.to_sym])

        # Do Delete
        return 500 unless service.delete_by_primary_key(params[primary_key_name.to_sym])

        204
      end
    end

    # Set up POST/insert functionality on the given resource
    def crud_post(resource_name, service_name, primary_key_name, api_options = {})
      api_options = get_defaults(api_options)
      post '/'+resource_name do
        service = settings.send(service_name)

        # Get The data
        begin
          data = JSON.parse(request.body.read)
        rescue Exception => e
          return 422
        end

        # Valid POST?
        return 422 unless service.valid_insert?(data)

        # Already Exists?
        return 409 if service.exists_by_primary_key?(data[primary_key_name])

        # Do Insert
        record = service.insert(data)

        # Other Error
        return 500 if record.nil?

        # Output new record
        JSON.fast_generate record
      end
    end

    # Return the given options with defaults set
    def get_defaults(api_options)
      defaults = {
        :enable_read => true,
        :enable_write => true,
        :enable_options => true,
        :enable_get_all => true,
        :enable_get => true,
        :enable_post => true,
        :enable_put => true,
        :enable_delete => true,
      }
      api_options.merge!(defaults) { |key, v1, v2| v1 }
    end
  end
end
