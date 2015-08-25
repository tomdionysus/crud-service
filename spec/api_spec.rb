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

      expect(inst).to receive(:crud_options).with(1,2,3,mock_opts)
      expect(inst).to receive(:crud_post).with(1,2,3,mock_opts)
      expect(inst).to receive(:crud_put).with(1,2,3,mock_opts)
      expect(inst).to receive(:crud_delete).with(1,2,3,mock_opts)
      expect(inst).to receive(:crud_get).with(1,2,3,mock_opts)
      expect(inst).to receive(:crud_get_all).with(1,2,3,mock_opts)

      inst.crud_api(1,2,3,{})
    end

    it 'should not call write methods if enable_write is false' do
      mock_opts = { :enable_write=>false, :enable_post=>true, :enable_put=>true, :enable_delete=>true }

      inst = TestAPI.new

      expect(inst).to receive(:crud_options).with(1,2,3,mock_opts)
      expect(inst).not_to receive(:crud_post).with(1,2,3,mock_opts)
      expect(inst).not_to receive(:crud_put).with(1,2,3,mock_opts)
      expect(inst).not_to receive(:crud_delete).with(1,2,3,mock_opts)
      expect(inst).to receive(:crud_get).with(1,2,3,mock_opts)
      expect(inst).to receive(:crud_get_all).with(1,2,3,mock_opts)

      inst.crud_api(1,2,3,mock_opts)
    end

     it 'should not call read methods if enable_read is false' do
      mock_opts = { :enable_read=>false, :enable_get=>true, :enable_get_all=>true }

      inst = TestAPI.new

      expect(inst).to receive(:crud_options).with(1,2,3,mock_opts)
      expect(inst).to receive(:crud_post).with(1,2,3,mock_opts)
      expect(inst).to receive(:crud_put).with(1,2,3,mock_opts)
      expect(inst).to receive(:crud_delete).with(1,2,3,mock_opts)
      expect(inst).not_to receive(:crud_get).with(1,2,3,mock_opts)
      expect(inst).not_to receive(:crud_get_all).with(1,2,3,mock_opts)

      inst.crud_api(1,2,3,mock_opts)
    end

    it 'should not call crud_post method if enable_post is false' do
      mock_opts = { :enable_read=>true, :enable_write=>true, :enable_post=>false }

      inst = TestAPI.new

      expect(inst).to receive(:crud_options).with(1,2,3,mock_opts)
      expect(inst).not_to receive(:crud_post).with(1,2,3,mock_opts)
      expect(inst).to receive(:crud_put).with(1,2,3,mock_opts)
      expect(inst).to receive(:crud_delete).with(1,2,3,mock_opts)
      expect(inst).to receive(:crud_get).with(1,2,3,mock_opts)
      expect(inst).to receive(:crud_get_all).with(1,2,3,mock_opts)

      inst.crud_api(1,2,3,mock_opts)
    end

    it 'should not call crud_put method if enable_put is false' do
      mock_opts = { :enable_read=>true, :enable_write=>true, :enable_put=>false }

      inst = TestAPI.new

      expect(inst).to receive(:crud_options).with(1,2,3,mock_opts)
      expect(inst).to receive(:crud_post).with(1,2,3,mock_opts)
      expect(inst).not_to receive(:crud_put).with(1,2,3,mock_opts)
      expect(inst).to receive(:crud_delete).with(1,2,3,mock_opts)
      expect(inst).to receive(:crud_get).with(1,2,3,mock_opts)
      expect(inst).to receive(:crud_get_all).with(1,2,3,mock_opts)

      inst.crud_api(1,2,3,mock_opts)
    end

    it 'should not call crud_delete method if enable_delete is false' do
      mock_opts = { :enable_read=>true, :enable_write=>true, :enable_delete=>false }

      inst = TestAPI.new

      expect(inst).to receive(:crud_options).with(1,2,3,mock_opts)
      expect(inst).to receive(:crud_post).with(1,2,3,mock_opts)
      expect(inst).to receive(:crud_put).with(1,2,3,mock_opts)
      expect(inst).not_to receive(:crud_delete).with(1,2,3,mock_opts)
      expect(inst).to receive(:crud_get).with(1,2,3,mock_opts)
      expect(inst).to receive(:crud_get_all).with(1,2,3,mock_opts)

      inst.crud_api(1,2,3,mock_opts)
    end

    it 'should not call crud_get method if enable_get is false' do
      mock_opts = { :enable_read=>true, :enable_write=>true, :enable_get=>false }

      inst = TestAPI.new

      expect(inst).to receive(:crud_options).with(1,2,3,mock_opts)
      expect(inst).to receive(:crud_post).with(1,2,3,mock_opts)
      expect(inst).to receive(:crud_put).with(1,2,3,mock_opts)
      expect(inst).to receive(:crud_delete).with(1,2,3,mock_opts)
      expect(inst).not_to receive(:crud_get).with(1,2,3,mock_opts)
      expect(inst).to receive(:crud_get_all).with(1,2,3,mock_opts)

      inst.crud_api(1,2,3,mock_opts)
    end

    it 'should not call crud_get_all method if enable_get_all is false' do
      mock_opts = { :enable_read=>true, :enable_write=>true, :enable_get_all=>false }

      inst = TestAPI.new

      expect(inst).to receive(:crud_options).with(1,2,3,mock_opts)
      expect(inst).to receive(:crud_post).with(1,2,3,mock_opts)
      expect(inst).to receive(:crud_put).with(1,2,3,mock_opts)
      expect(inst).to receive(:crud_delete).with(1,2,3,mock_opts)
      expect(inst).to receive(:crud_get).with(1,2,3,mock_opts)
      expect(inst).not_to receive(:crud_get_all).with(1,2,3,mock_opts)

      inst.crud_api(1,2,3,mock_opts)
    end
  end

end