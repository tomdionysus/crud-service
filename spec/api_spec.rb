require "spec_helper"

class TestAPI
  include CrudService::Api
end

describe CrudService::Api do

  describe '#get_defaults' do

    it 'should produce correct fields' do
      inst = TestAPI.new

      mock_opts = {
        :enable_read=>true,
        :enable_write=>true,
        :enable_options=>true,
        :enable_get_all=>true,
        :enable_get=>true,
        :enable_post=>true,
        :enable_put=>true,
        :enable_delete=>true
      }

      expect(inst.get_defaults({})).to eq(mock_opts)
    end

    it 'should not overwrite existing fields' do
      inst = TestAPI.new

      mock_opts = {
        :enable_read=>true,
        :enable_write=>true,
        :enable_options=>false,
        :enable_get_all=>true,
        :enable_get=>true,
        :enable_post=>true,
        :enable_put=>true,
        :enable_delete=>true
      }

      expect(inst.get_defaults({:enable_options=>false})).to eq(mock_opts)
    end

  end
  describe '#crud_api' do
    it 'should call correct methods in correct order for defaults' do
      mock_opts = {
        :enable_read=>true,
        :enable_write=>true,
        :enable_options=>true,
        :enable_get_all=>true,
        :enable_get=>true,
        :enable_post=>true,
        :enable_put=>true,
        :enable_delete=>true
      }

      inst = TestAPI.new

      expect(inst).to receive(:crud_options).with(1,mock_opts)
      expect(inst).to receive(:crud_post).with(1,2,3,mock_opts)
      expect(inst).to receive(:crud_put).with(1,2,3,mock_opts)
      expect(inst).to receive(:crud_delete).with(1,2,3,mock_opts)
      expect(inst).to receive(:crud_get).with(1,2,3,mock_opts)
      expect(inst).to receive(:crud_get_all).with(1,2,mock_opts)

      inst.crud_api(1,2,3,{})
    end

    it 'should not call write methods if enable_write is false' do
      mock_opts = { :enable_write=>false, :enable_post=>true, :enable_put=>true, :enable_delete=>true }

      inst = TestAPI.new

      expect(inst).to receive(:crud_options).with(1,mock_opts)
      expect(inst).not_to receive(:crud_post).with(1,2,3,mock_opts)
      expect(inst).not_to receive(:crud_put).with(1,2,3,mock_opts)
      expect(inst).not_to receive(:crud_delete).with(1,2,3,mock_opts)
      expect(inst).to receive(:crud_get).with(1,2,3,mock_opts)
      expect(inst).to receive(:crud_get_all).with(1,2,mock_opts)

      inst.crud_api(1,2,3,mock_opts)
    end

    it 'should not call read methods if enable_read is false' do
      mock_opts = { :enable_read=>false, :enable_get=>true, :enable_get_all=>true }

      inst = TestAPI.new

      expect(inst).to receive(:crud_options).with(1,mock_opts)
      expect(inst).to receive(:crud_post).with(1,2,3,mock_opts)
      expect(inst).to receive(:crud_put).with(1,2,3,mock_opts)
      expect(inst).to receive(:crud_delete).with(1,2,3,mock_opts)
      expect(inst).not_to receive(:crud_get).with(1,2,3,mock_opts)
      expect(inst).not_to receive(:crud_get_all).with(1,2,mock_opts)

      inst.crud_api(1,2,3,mock_opts)
    end

    it 'should not call crud_post method if enable_post is false' do
      mock_opts = { :enable_read=>true, :enable_write=>true, :enable_post=>false }

      inst = TestAPI.new

      expect(inst).to receive(:crud_options).with(1,mock_opts)
      expect(inst).not_to receive(:crud_post).with(1,2,3,mock_opts)
      expect(inst).to receive(:crud_put).with(1,2,3,mock_opts)
      expect(inst).to receive(:crud_delete).with(1,2,3,mock_opts)
      expect(inst).to receive(:crud_get).with(1,2,3,mock_opts)
      expect(inst).to receive(:crud_get_all).with(1,2,mock_opts)

      inst.crud_api(1,2,3,mock_opts)
    end

    it 'should not call crud_put method if enable_put is false' do
      mock_opts = { :enable_read=>true, :enable_write=>true, :enable_put=>false }

      inst = TestAPI.new

      expect(inst).to receive(:crud_options).with(1,mock_opts)
      expect(inst).to receive(:crud_post).with(1,2,3,mock_opts)
      expect(inst).not_to receive(:crud_put).with(1,2,3,mock_opts)
      expect(inst).to receive(:crud_delete).with(1,2,3,mock_opts)
      expect(inst).to receive(:crud_get).with(1,2,3,mock_opts)
      expect(inst).to receive(:crud_get_all).with(1,2,mock_opts)

      inst.crud_api(1,2,3,mock_opts)
    end

    it 'should not call crud_delete method if enable_delete is false' do
      mock_opts = { :enable_read=>true, :enable_write=>true, :enable_delete=>false }

      inst = TestAPI.new

      expect(inst).to receive(:crud_options).with(1,mock_opts)
      expect(inst).to receive(:crud_post).with(1,2,3,mock_opts)
      expect(inst).to receive(:crud_put).with(1,2,3,mock_opts)
      expect(inst).not_to receive(:crud_delete).with(1,2,3,mock_opts)
      expect(inst).to receive(:crud_get).with(1,2,3,mock_opts)
      expect(inst).to receive(:crud_get_all).with(1,2,mock_opts)

      inst.crud_api(1,2,3,mock_opts)
    end

    it 'should not call crud_get method if enable_get is false' do
      mock_opts = { :enable_read=>true, :enable_write=>true, :enable_get=>false }

      inst = TestAPI.new

      expect(inst).to receive(:crud_options).with(1,mock_opts)
      expect(inst).to receive(:crud_post).with(1,2,3,mock_opts)
      expect(inst).to receive(:crud_put).with(1,2,3,mock_opts)
      expect(inst).to receive(:crud_delete).with(1,2,3,mock_opts)
      expect(inst).not_to receive(:crud_get).with(1,2,3,mock_opts)
      expect(inst).to receive(:crud_get_all).with(1,2,mock_opts)

      inst.crud_api(1,2,3,mock_opts)
    end

    it 'should not call crud_get_all method if enable_get_all is false' do
      mock_opts = { :enable_read=>true, :enable_write=>true, :enable_get_all=>false }

      inst = TestAPI.new

      expect(inst).to receive(:crud_options).with(1,mock_opts)
      expect(inst).to receive(:crud_post).with(1,2,3,mock_opts)
      expect(inst).to receive(:crud_put).with(1,2,3,mock_opts)
      expect(inst).to receive(:crud_delete).with(1,2,3,mock_opts)
      expect(inst).to receive(:crud_get).with(1,2,3,mock_opts)
      expect(inst).not_to receive(:crud_get_all).with(1,2,mock_opts)

      inst.crud_api(1,2,3,mock_opts)
    end
  end

  describe '#crud_options' do
    it 'should call get_defaults and options' do
      mock_opts = { :enable_get_all=>false }

      inst = TestAPI.new

      expect(inst).to receive(:get_defaults).with(mock_opts)
      expect(inst).to receive(:options) do |resname, &block|
        expect(resname).to eq('/resource')
        expect(block.call).to eq(204)
      end

      inst.crud_options('resource', mock_opts)
    end
  end

  describe '#crud_put' do
    it 'should call get_defaults and options, return 404 if record doesnt exist' do
      mock_opts = { :enable_get_all=>false }

      inst = TestAPI.new

      expect(inst).to receive(:get_defaults).with(mock_opts)
      expect(inst).to receive(:put) do |resname, &block|
        expect(resname).to eq('/resource/:primary')

        settings = OpenStruct.new
        service = OpenStruct.new
        expect(inst).to receive(:settings).and_return(settings)
        expect(settings).to receive(:send).with('service').and_return(service)

        expect(inst).to receive(:params).and_return({:primary=>34567})
        expect(service).to receive(:exists_by_primary_key?).with(34567).and_return(false)
        block.call

      end

      expect(inst.crud_put('resource','service','primary',mock_opts)).to eq(404)
    end

    it 'should call get_defaults and options, return 422 if JSON parse fails' do
      mock_opts = { :enable_get_all=>false }

      inst = TestAPI.new

      expect(inst).to receive(:get_defaults).with(mock_opts)
      expect(inst).to receive(:put) do |resname, &block|
        expect(resname).to eq('/resource/:primary')

        settings = OpenStruct.new
        service = OpenStruct.new
        expect(inst).to receive(:settings).and_return(settings)
        expect(settings).to receive(:send).with('service').and_return(service)

        expect(inst).to receive(:params).and_return({:primary=>34567})
        expect(service).to receive(:exists_by_primary_key?).with(34567).and_return(true)

        request = OpenStruct.new({:body=>OpenStruct.new({:read => '{"one":1'})})
        expect(inst).to receive(:request).and_return(request)

        block.call
      end

      expect(inst.crud_put('resource','service','primary',mock_opts)).to eq(422)
    end

    it 'should call get_defaults and options, return 500 if update fails' do
      mock_opts = { :enable_get_all=>false }

      inst = TestAPI.new

      expect(inst).to receive(:get_defaults).with(mock_opts)
      expect(inst).to receive(:put) do |resname, &block|
        expect(resname).to eq('/resource/:primary')

        settings = OpenStruct.new
        service = OpenStruct.new
        expect(inst).to receive(:settings).and_return(settings)
        expect(settings).to receive(:send).with('service').and_return(service)

        expect(inst).to receive(:params).twice.and_return({:primary=>34567})
        expect(service).to receive(:exists_by_primary_key?).with(34567).and_return(true)

        request = OpenStruct.new({:body=>OpenStruct.new({:read => '{"one":1}'})})
        expect(inst).to receive(:request).and_return(request)

        expect(service).to receive(:valid_update?).with({"one"=>1}).and_return(true)

        expect(service).to receive(:update_by_primary_key).with(34567, {"one"=>1}).and_return(nil)

        block.call
      end

      expect(inst.crud_put('resource','service','primary',mock_opts)).to eq(500)
    end

    it 'should call get_defaults and options, return JSON string of record' do
      mock_opts = { :enable_get_all=>false }

      inst = TestAPI.new

      expect(inst).to receive(:get_defaults).with(mock_opts)
      expect(inst).to receive(:put) do |resname, &block|
        expect(resname).to eq('/resource/:primary')

        settings = OpenStruct.new
        service = OpenStruct.new
        expect(inst).to receive(:settings).and_return(settings)
        expect(settings).to receive(:send).with('service').and_return(service)

        expect(inst).to receive(:params).twice.and_return({:primary=>34567})
        expect(service).to receive(:exists_by_primary_key?).with(34567).and_return(true)

        request = OpenStruct.new({:body=>OpenStruct.new({:read => '{"one":1}'})})
        expect(inst).to receive(:request).and_return(request)

        expect(service).to receive(:valid_update?).with({"one"=>1}).and_return(true)

        expect(service).to receive(:update_by_primary_key).with(34567, {"one"=>1}).and_return({"two"=>2})

        block.call
      end

      expect(inst.crud_put('resource','service','primary',mock_opts)).to eq('{"two":2}')
    end
  end

  describe '#crud_get' do
    it 'should call get_defaults and options, return 400 if bad query' do
      mock_opts = { :enable_get_all=>false }

      inst = TestAPI.new

      expect(inst).to receive(:get_defaults).with(mock_opts)
      expect(inst).to receive(:get) do |resname, &block|
        expect(resname).to eq('/resource/:primary')

        service = OpenStruct.new
        settings = OpenStruct.new("service_name" => service)
        params = OpenStruct.new
        expect(inst).to receive(:settings).and_return(settings)
        expect(inst).to receive(:params).twice.and_return(params)

        expect(inst).to receive(:sanitize_params).with(params)
        expect(service).to receive(:valid_query?).with(params).and_return(false)

        block.call
      end

      expect(inst.crud_get('resource','service_name','primary',mock_opts)).to eq(400)
    end

    it 'should call get_defaults and options, return 404 if not found' do
      mock_opts = { :enable_get_all=>false }

      inst = TestAPI.new

      expect(inst).to receive(:get_defaults).with(mock_opts)
      expect(inst).to receive(:get) do |resname, &block|
        expect(resname).to eq('/resource/:primary')

        service = OpenStruct.new
        settings = OpenStruct.new("service_name" => service)
        params = OpenStruct.new
        expect(inst).to receive(:settings).and_return(settings)
        expect(inst).to receive(:params).thrice.and_return(params)

        expect(inst).to receive(:sanitize_params).with(params)
        expect(service).to receive(:valid_query?).with(params).and_return(true)

        expect(service).to receive(:get_one_by_query).with(params).and_return(nil)

        block.call
      end

      expect(inst.crud_get('resource','service_name','primary',mock_opts)).to eq(404)
    end

    it 'should call get_defaults and options, return 404 if not found' do
      mock_opts = { :enable_get_all=>false }

      inst = TestAPI.new

      expect(inst).to receive(:get_defaults).with(mock_opts)
      expect(inst).to receive(:get) do |resname, &block|
        expect(resname).to eq('/resource/:primary')

        service = OpenStruct.new
        settings = OpenStruct.new("service_name" => service)
        params = OpenStruct.new
        expect(inst).to receive(:settings).and_return(settings)
        expect(inst).to receive(:params).thrice.and_return(params)

        expect(inst).to receive(:sanitize_params).with(params)
        expect(service).to receive(:valid_query?).with(params).and_return(true)

        expect(service).to receive(:get_one_by_query).with(params).and_return({"three"=>3})

        block.call
      end

      expect(inst.crud_get('resource','service_name','primary',mock_opts)).to eq('{"three":3}')
    end
  end

  describe '#crud_get_all' do
    it 'should call get_defaults and options, return 400 if bad query' do
      mock_opts = { :enable_get_all=>false }

      inst = TestAPI.new

      expect(inst).to receive(:get_defaults).with(mock_opts)
      expect(inst).to receive(:get) do |resname, &block|
        expect(resname).to eq('/resource')

        service = OpenStruct.new
        settings = OpenStruct.new("service_name" => service)
        params = OpenStruct.new
        expect(inst).to receive(:settings).and_return(settings)
        expect(inst).to receive(:params).twice.and_return(params)

        expect(inst).to receive(:sanitize_params).with(params)
        expect(service).to receive(:valid_query?).with(params).and_return(false)

        block.call
      end

      expect(inst.crud_get_all('resource','service_name',mock_opts)).to eq(400)
    end

    it 'should call get_defaults and options, return JSON string from records' do
      mock_opts = { :enable_get_all=>false }

      inst = TestAPI.new

      expect(inst).to receive(:get_defaults).with(mock_opts)
      expect(inst).to receive(:get) do |resname, &block|
        expect(resname).to eq('/resource')

        service = OpenStruct.new
        settings = OpenStruct.new("service_name" => service)
        params = OpenStruct.new
        expect(inst).to receive(:settings).and_return(settings)
        expect(inst).to receive(:params).thrice.and_return(params)

        expect(inst).to receive(:sanitize_params).with(params)
        expect(service).to receive(:valid_query?).with(params).and_return(true)

        expect(service).to receive(:get_all_by_query).with(params).and_return([{"three"=>3}])

        block.call
      end

      expect(inst.crud_get_all('resource','service_name',mock_opts)).to eq('[{"three":3}]')
    end
  end

  describe '#crud_delete' do
    it 'should call get_defaults and options, return 404 if not found' do
      mock_opts = { :enable_get_all=>false }

      inst = TestAPI.new

      expect(inst).to receive(:get_defaults).with(mock_opts)
      expect(inst).to receive(:delete) do |resname, &block|
        expect(resname).to eq('/resource/:primary')

        service = OpenStruct.new
        settings = OpenStruct.new("service_name" => service)
        params = OpenStruct.new({"primary"=>6})
        expect(inst).to receive(:settings).and_return(settings)
        expect(inst).to receive(:params).and_return(params)

        expect(service).to receive(:exists_by_primary_key?).with(6).and_return(false)

        block.call
      end

      expect(inst.crud_delete('resource','service_name','primary',mock_opts)).to eq(404)
    end

    it 'should call get_defaults and options, return 500 if record failed to delete' do
      mock_opts = { :enable_get_all=>false }

      inst = TestAPI.new

      expect(inst).to receive(:get_defaults).with(mock_opts)
      expect(inst).to receive(:delete) do |resname, &block|
        expect(resname).to eq('/resource/:primary')

        service = OpenStruct.new
        settings = OpenStruct.new("service_name" => service)
        params = OpenStruct.new({"primary"=>6})
        expect(inst).to receive(:settings).and_return(settings)
        expect(inst).to receive(:params).twice.and_return(params)

        expect(service).to receive(:exists_by_primary_key?).with(6).and_return(true)
        expect(service).to receive(:delete_by_primary_key).with(6).and_return(false)

        block.call
      end

      expect(inst.crud_delete('resource','service_name','primary',mock_opts)).to eq(500)
    end

    it 'should call get_defaults and options, return 204 if record deletes ok' do
      mock_opts = { :enable_get_all=>false }

      inst = TestAPI.new

      expect(inst).to receive(:get_defaults).with(mock_opts)
      expect(inst).to receive(:delete) do |resname, &block|
        expect(resname).to eq('/resource/:primary')

        service = OpenStruct.new
        settings = OpenStruct.new("service_name" => service)
        params = OpenStruct.new({"primary"=>6})
        expect(inst).to receive(:settings).and_return(settings)
        expect(inst).to receive(:params).twice.and_return(params)

        expect(service).to receive(:exists_by_primary_key?).with(6).and_return(true)
        expect(service).to receive(:delete_by_primary_key).with(6).and_return(true)

        block.call
      end

      expect(inst.crud_delete('resource','service_name','primary',mock_opts)).to eq(204)
    end
  end

  describe '#crud_put' do
    it 'should call get_defaults and options, return 422 if body parse fails' do
      mock_opts = { :enable_get_all=>false }

      inst = TestAPI.new

      expect(inst).to receive(:get_defaults).with(mock_opts)
      expect(inst).to receive(:post) do |resname, &block|
        expect(resname).to eq('/resource')

        settings = OpenStruct.new
        service = OpenStruct.new
        expect(inst).to receive(:settings).and_return(settings)
        expect(settings).to receive(:send).with('service').and_return(service)

        request = OpenStruct.new({:body=>OpenStruct.new({:read => '{"one":1'})})
        expect(inst).to receive(:request).and_return(request)
        block.call
      end

      expect(inst.crud_post('resource','service','primary',mock_opts)).to eq(422)
    end

    it 'should call get_defaults and options, return 422 if non valid insert' do
      mock_opts = { :enable_get_all=>false }

      inst = TestAPI.new

      expect(inst).to receive(:get_defaults).with(mock_opts)
      expect(inst).to receive(:post) do |resname, &block|
        expect(resname).to eq('/resource')

        settings = OpenStruct.new
        service = OpenStruct.new
        expect(inst).to receive(:settings).and_return(settings)
        expect(settings).to receive(:send).with('service').and_return(service)

        request = OpenStruct.new({:body=>OpenStruct.new({:read => '{"one":1}'})})
        expect(inst).to receive(:request).and_return(request)

        expect(service).to receive(:valid_insert?).with({"one"=>1}).and_return(false)

        block.call
      end

      expect(inst.crud_post('resource','service','one',mock_opts)).to eq(422)
    end

    it 'should call get_defaults and options, return 409 if pk already exists' do
      mock_opts = { :enable_get_all=>false }

      inst = TestAPI.new

      expect(inst).to receive(:get_defaults).with(mock_opts)
      expect(inst).to receive(:post) do |resname, &block|
        expect(resname).to eq('/resource')

        settings = OpenStruct.new
        service = OpenStruct.new
        expect(inst).to receive(:settings).and_return(settings)
        expect(settings).to receive(:send).with('service').and_return(service)

        request = OpenStruct.new({:body=>OpenStruct.new({:read => '{"one":1}'})})
        expect(inst).to receive(:request).and_return(request)

        expect(service).to receive(:valid_insert?).with({"one"=>1}).and_return(true)
        expect(service).to receive(:exists_by_primary_key?).with(1).and_return(true)

        block.call
      end

      expect(inst.crud_post('resource','service','one',mock_opts)).to eq(409)
    end

    it 'should call get_defaults and options, return 500 if record fails to insert' do
      mock_opts = { :enable_get_all=>false }

      inst = TestAPI.new

      expect(inst).to receive(:get_defaults).with(mock_opts)
      expect(inst).to receive(:post) do |resname, &block|
        expect(resname).to eq('/resource')

        settings = OpenStruct.new
        service = OpenStruct.new
        expect(inst).to receive(:settings).and_return(settings)
        expect(settings).to receive(:send).with('service').and_return(service)

        request = OpenStruct.new({:body=>OpenStruct.new({:read => '{"one":1}'})})
        expect(inst).to receive(:request).and_return(request)

        expect(service).to receive(:valid_insert?).with({"one"=>1}).and_return(true)
        expect(service).to receive(:exists_by_primary_key?).with(1).and_return(false)
        expect(service).to receive(:insert).with({"one"=>1}).and_return({"five"=>5})

        block.call
      end

      expect(inst.crud_post('resource','service','one',mock_opts)).to eq("{\"five\":5}")
    end

  end
end