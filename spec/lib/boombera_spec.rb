require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe Boombera do
  before(:each) do
    Boombera.stub!(:version => '1.2.3')
    Boombera.stub!(:database_version => '1.2.3')
  end

  describe '.new' do
    it 'connects to the specified database on the local couchdb server' do
      db = stub(CouchRest::Database)
      CouchRest.should_receive(:database!) \
        .with("my_db") \
        .and_return(db)
      boombera = Boombera.new('my_db')
      boombera.db.should == db
    end

    it 'raises a VersionMismatch error with expected version if the database does not match VERSION' do
      Boombera.stub!(:version => '1.2.2')
      lambda { Boombera.new('boombera_test') }.should \
        raise_error(Boombera::VersionMismatch, "Database expects Boombera 1.2.3")
    end

    it 'raises a VersionMismatch error if the database does not have a boombera_version document' do
      Boombera.stub!(:database_version => nil)
      lambda { Boombera.new('boombera_test') }.should \
        raise_error(Boombera::VersionMismatch, "Database does not specify a Boombera version")
    end
  end

  describe '#put' do
    it 'saves the content item in the database and returns a Result' do
      CouchRest.stub!(:database! => :database)
      Boombera::ContentItem.should_receive(:create_or_update) \
        .with(:database, '/foo', 'bar') \
        .and_return(:the_result)
      boombera = Boombera.new('boombera_test')
      boombera.put('/foo', 'bar').should == :the_result
    end
  end
end

# This is set up as a seperate describe block, because we obviously can't stub
# out .version and .database_version when those are the methods being tested.
describe Boombera do
  describe '.version' do
    it 'returns the current version as specified in the VERSION file' do
      File.should_receive(:read) \
        .with(File.expand_path(File.join(File.dirname(__FILE__), '..', '..',
                                         'VERSION'))) \
        .and_return('1.2.3')
      Boombera.version.should == '1.2.3'
    end
  end

  describe '.database_version' do
    it 'returns the version of Boombera that the database expects to be working with' do
      db = mock(CouchRest::Database)
      db.should_receive(:get).with('_design/boombera') \
        .and_return({'gem_version' => '1.2.3'})
      Boombera.database_version(db).should == '1.2.3'
    end

    it 'returns nil if no version is specified in the database' do
      db = mock(CouchRest::Database)
      db.stub!(:get).and_raise(RestClient::ResourceNotFound)
      Boombera.database_version(db).should be_nil
    end
  end
end
