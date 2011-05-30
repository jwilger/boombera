require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe Boombera do
  let(:db) do
    db = stub(CouchRest::Database)
    CouchRest.stub!(:database! => db)
    db
  end

  before(:each) do
    Boombera.stub!(:version => '1.2.3')
    Boombera.stub!(:database_version => '1.2.3')
  end

  describe '.new' do
    it 'connects to the specified database on the local couchdb server' do
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
    let(:content_item) { mock(Boombera::ContentItem) }
    let(:content_item_save_expectations) do
      lambda {
        content_item.should_receive(:body=).with('bar')
        content_item.should_receive(:save).and_return(true)
        boombera = Boombera.new('boombera_test')
        boombera.put('/foo', 'bar').should == true
      }
    end

    context "to an existing path" do
      it 'updates and saves the existing content item' do
        Boombera::ContentItem.should_receive(:get).with('/foo', db).and_return(content_item)
        content_item_save_expectations.call
      end
    end

    context "to a new path" do
      it 'creates and saves the existing content item' do
        Boombera::ContentItem.stub!(:get => nil)
        Boombera::ContentItem.should_receive(:new) \
          .with(:path => '/foo', :database => db) \
          .and_return(content_item)
        content_item_save_expectations.call
      end
    end
  end

  describe '#get' do
    it 'gets the content item at the specified path from the current database' do
      db.as_null_object
      Boombera::ContentItem.should_receive(:get).with('/foo', db)
      boombera = Boombera.new('boombera_test')
      boombera.get('/foo')
    end
  end

  describe '.install_design_doc!' do
    context 'when the design doc does not yet exist' do
      it 'creates the design doc on the specified database' do
        CouchRest.should_receive(:database!) \
          .with('boombera_test') \
          .and_return(db)
        db.should_receive(:get) \
          .with('_design/boombera') \
          .and_raise(RestClient::ResourceNotFound)
        db.should_receive(:save_doc) \
          .with(Boombera.design_doc)
        Boombera.install_design_doc!('boombera_test')
      end
    end

    context 'when the design doc already exists' do
      it 'updates the design doc on the specified database' do
        CouchRest.should_receive(:database!) \
          .with('boombera_test') \
          .and_return(db)
        db.should_receive(:get) \
          .with('_design/boombera') \
          .and_return({'_id' => '_design/boombera', '_rev' => '123'})
        db.should_receive(:save_doc).with(Boombera.design_doc.merge('_rev' => '123'))
        Boombera.install_design_doc!('boombera_test')
      end
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
    let(:db) { stub(CouchRest::Database) }

    it 'returns the version of Boombera that the database expects to be working with' do
      db.should_receive(:get).with('_design/boombera') \
        .and_return({'gem_version' => '1.2.3'})
      Boombera.database_version(db).should == '1.2.3'
    end

    it 'returns nil if no version is specified in the database' do
      db.stub!(:get).and_raise(RestClient::ResourceNotFound)
      Boombera.database_version(db).should be_nil
    end
  end
end
