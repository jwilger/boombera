require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'spec_helper'))

describe Boombera::ContentItem do
  describe '.create_or_update' do
    context 'when the content item does not exist yet' do
      it 'creates the content with #create and returns the result' do
        Boombera::ContentItem.stub!(:exists? => false)
        Boombera::ContentItem.should_receive(:create) \
          .with(:database, '/foo', 'bar') \
          .and_return(:created_result)
        result = Boombera::ContentItem.create_or_update(:database, '/foo', 'bar')
        result.should == :created_result
      end
    end

    context 'when the content item already exists' do
      it 'updates the content and returns the result' do
        Boombera::ContentItem.stub!(:exists? => true)
        Boombera::ContentItem.should_receive(:update) \
          .with(:database, '/foo', 'bar') \
          .and_return(:updated_result)
        result = Boombera::ContentItem.create_or_update(:database, '/foo', 'bar')
        result.should == :updated_result
      end
    end
  end

  describe '.create' do
    it 'saves the content to the specified database' do
      db = mock(CouchRest::Database)
      db.should_receive(:save_doc) \
        .with({:path => '/foo', :body => 'bar'})
      Boombera::ContentItem.create(db, '/foo', 'bar')
    end

    it 'returns a Result with a :created status' do
      db = stub(CouchRest::Database).as_null_object
      result = Boombera::ContentItem.create(db, '/foo', 'bar')
      result.status.should == :created
    end
  end

  describe '.exists?' do
    it 'returns true when the database has a content item with the specified path' do
      fail "Need to come up with a way to have the views installed"
      db = mock(CouchRest::Database)
      db.should_receive(:view) \
        .with('boombera/content_map', :key => '/foo') \
        .and_return({'total_rows' => 1})
      Boombera::ContentItem.exists?(db, '/foo').should == true
    end

    it 'returns false when the database does not have a content item with the specified path' do
      db = mock(CouchRest::Database)
      db.should_receive(:view) \
        .with('boombera/content_map', :key => '/foo') \
        .and_return({'total_rows' => 0})
      Boombera::ContentItem.exists?(db, '/foo').should == false
    end
  end
end
