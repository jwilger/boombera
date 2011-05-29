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

  describe '.update' do
    it 'saves the content to the specified database' do
      db = stub(CouchRest::Database).as_null_object
      doc = mock(Boombera::ContentItem)
      doc.should_receive(:body=).with('bar')
      doc.should_receive(:save)
      Boombera::ContentItem.should_receive(:get).with(db, '/foo').and_return(doc)
      Boombera::ContentItem.update(db, '/foo', 'bar')
    end

    it 'returns a Result with an :updated status' do
      db = stub(CouchRest::Database).as_null_object
      result = Boombera::ContentItem.update(db, '/foo', 'bar')
      result.status.should == :updated
    end
  end

  describe '.get' do
    context 'with an existing content item' do
      it 'returns a ContentItem instance for the found document' do
        view_result = {'rows' => [{'id' => '123'}]}
        db = mock(CouchRest::Database)
        db.should_receive(:view) \
          .with('boombera/content_map', :key => '/foo') \
          .and_return(view_result)
        db.should_receive(:get) \
          .with('123') \
          .and_return({'path' => '/foo', 'body' => 'bar'})
        result = Boombera::ContentItem.get(db, '/foo')
        result.should be_kind_of(Boombera::ContentItem)
        result.path.should == '/foo'
        result.body.should == 'bar'
      end
    end
  end

  describe '.exists?' do
    it 'returns true when the database has a content item with the specified path' do
      view_result_with_rows = {'rows' => [{'id' => '123'}]}
      db = mock(CouchRest::Database)
      db.should_receive(:view) \
        .with('boombera/content_map', :key => '/foo') \
        .and_return(view_result_with_rows)
      Boombera::ContentItem.exists?(db, '/foo').should == true
    end

    it 'returns false when the database does not have a content item with the specified path' do
      view_result_without_rows = {'rows' => []}
      db = mock(CouchRest::Database)
      db.should_receive(:view) \
        .with('boombera/content_map', :key => '/foo') \
        .and_return(view_result_without_rows)
      Boombera::ContentItem.exists?(db, '/foo').should == false
    end
  end

  describe '#path' do
    it 'returns the path from the associated document' do
      content = Boombera::ContentItem.new({'path' => '/index.html'})
      content.path.should == '/index.html'
    end
  end

  describe '#body' do
    it 'returns the body from the associated document' do
      content = Boombera::ContentItem.new({'body' => 'foo bar baz'})
      content.body.should == 'foo bar baz'
    end
  end

  describe '#body=' do
    it 'overwrites the current contents of the document body' do
      content = Boombera::ContentItem.new({'body' => 'foo'})
      content.body = 'bar'
      content.body.should == 'bar'
    end
  end

  describe '#save' do
    it 'saves the document to the database' do
      doc = mock(CouchRest::Document)
      doc.should_receive(:save)
      content = Boombera::ContentItem.new(doc)
      content.save
    end
  end
end
