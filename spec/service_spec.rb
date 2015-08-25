require "spec_helper"

describe CrudService::Service do
  before(:each) do
    @mock_dal = double('CrudService::Dal')
    @mock_log = double('Log')

    @generic_service = CrudService::Service.new(@mock_dal, @mock_log)
  end

  describe '#initialize' do 
    it 'should inject dependencies correctly' do
      expect(@generic_service.dal).to eq(@mock_dal)
      expect(@generic_service.log).to eq(@mock_log)
    end
  end

  describe '#insert' do
    it 'should call DAL insert' do
      query = { "one" => "two" }
      expect(@mock_dal).to receive(:insert).with(query).and_return(true)
      expect(@generic_service.insert(query)).to eq(true)
    end
  end

  describe "#get_all_by_query" do
    it "should return all records from DAL with no relations" do

      data = {:code_numeric=>123, :name => "Great Britain"}

      query = { 'code_alpha_3' => 'GBR' }

      expect(@mock_dal).to receive(:get_all_by_query)
        .with(query)
        .and_return(data)

      expect(@mock_dal).to receive(:map_in_included_relations!)
        .with(data,query)
        .and_return(data)

      expect(@generic_service.get_all_by_query(query)).to eq(data)
    end
  end

  describe '#get_one_by_query' do
    it 'should call DAL get_one_by_query' do
      query = { "one" => "two" }
      expect(@mock_dal).to receive(:get_all_by_query).with(query).and_return([query])
      expect(@mock_dal).to receive(:map_in_included_relations!).and_return(true)
      expect(@generic_service.get_one_by_query(query)).to eq(query)
    end
  end

  describe '#update_by_primary_key' do
    it 'should call DAL update_by_primary_key' do
      query = { "one" => "two" }
      expect(@mock_dal).to receive(:update_by_primary_key).with(2,query).and_return(true)
      expect(@generic_service.update_by_primary_key(2,query)).to eq(true)
    end
  end

  describe '#delete_by_primary_key' do
    it 'should call DAL delete_by_primary_key' do
      query = { "one" => "two" }
      expect(@mock_dal).to receive(:delete_by_primary_key).with(query).and_return(true)
      expect(@generic_service.delete_by_primary_key(query)).to eq(true)
    end
  end

  describe '#exists_by_primary_key?' do
    it 'should call DAL exists_by_primary_key?' do
      query = { "one" => "two" }
      expect(@mock_dal).to receive(:exists_by_primary_key?).with(query).and_return(true)
      expect(@generic_service.exists_by_primary_key?(query)).to eq(true)
    end
  end

  describe '#valid_insert?' do 
    it 'should call DAL valid_insert?' do
      query = { "one" => "two" }
      expect(@mock_dal).to receive(:valid_insert?).with(query).and_return(true)

      expect(@generic_service.valid_insert?(query)).to eq(true)
    end
  end

  describe '#valid_query?' do 
    it 'should call DAL valid_query?' do
      query = { "one" => "two" }
      expect(@mock_dal).to receive(:valid_query?).with(query).and_return(true)

      expect(@generic_service.valid_query?(query)).to eq(true)
    end
  end

  describe '#valid_update?' do 
    it 'should call DAL valid_update?' do
      query = { "one" => "two" }
      expect(@mock_dal).to receive(:valid_update?).with(query).and_return(true)

      expect(@generic_service.valid_update?(query)).to eq(true)
    end
  end
end
