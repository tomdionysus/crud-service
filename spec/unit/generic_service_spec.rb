require "generic_service"

describe Service::GenericService do
  before(:each) do
    @mock_dal = double('DAL::GenericDal')
    @mock_log = double('Log')

    @generic_service = Service::GenericService.new(@mock_dal, @mock_log)
  end

  describe '#initialize' do 
    it 'should inject dependencies correctly' do
      @generic_service.dal.should eq @mock_dal
      @generic_service.log.should eq @mock_log
    end
  end

  describe '#insert' do
    it 'should call DAL insert' do
      query = { "one" => "two" }
      @mock_dal.should_receive(:insert).with(query).and_return(true)
      @generic_service.insert(query).should eq true
    end
  end

  describe "#get_all_by_query" do
    it "should return all records from DAL with no relations" do

      data = {:code_numeric=>123, :name => "Great Britain"}

      query = { 'code_alpha_3' => 'GBR' }

      @mock_dal.should_receive(:get_all_by_query)
        .with(query)
        .and_return(data)

      @mock_dal.should_receive(:map_in_included_relations!)
        .with(data,query)
        .and_return(data)

      @generic_service.get_all_by_query(query).should eq(data)
    end
  end

  describe '#get_one_by_query' do
    it 'should call DAL get_one_by_query' do
      query = { "one" => "two" }
      @mock_dal.should_receive(:get_all_by_query).with(query).and_return([query])
      @mock_dal.should_receive(:map_in_included_relations!).and_return(true)
      @generic_service.get_one_by_query(query).should eq query
    end
  end

  describe '#update_by_primary_key' do
    it 'should call DAL update_by_primary_key' do
      query = { "one" => "two" }
      @mock_dal.should_receive(:update_by_primary_key).with(2,query).and_return(true)
      @generic_service.update_by_primary_key(2,query).should eq true
    end
  end

  describe '#delete_by_primary_key' do
    it 'should call DAL delete_by_primary_key' do
      query = { "one" => "two" }
      @mock_dal.should_receive(:delete_by_primary_key).with(query).and_return(true)
      @generic_service.delete_by_primary_key(query).should eq true
    end
  end

  describe '#exists_by_primary_key?' do
    it 'should call DAL exists_by_primary_key?' do
      query = { "one" => "two" }
      @mock_dal.should_receive(:exists_by_primary_key?).with(query).and_return(true)
      @generic_service.exists_by_primary_key?(query).should eq true
    end
  end

  describe '#valid_insert?' do 
    it 'should call DAL valid_insert?' do
      query = { "one" => "two" }
      @mock_dal.should_receive(:valid_insert?).with(query).and_return(true)

      @generic_service.valid_insert?(query).should eq true
    end
  end

  describe '#valid_query?' do 
    it 'should call DAL valid_query?' do
      query = { "one" => "two" }
      @mock_dal.should_receive(:valid_query?).with(query).and_return(true)

      @generic_service.valid_query?(query).should eq true
    end
  end

  describe '#valid_update?' do 
    it 'should call DAL valid_update?' do
      query = { "one" => "two" }
      @mock_dal.should_receive(:valid_update?).with(query).and_return(true)

      @generic_service.valid_update?(query).should eq true
    end
  end
end