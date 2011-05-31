require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'spec_helper'))

describe Boombera::ContentItem do
  describe '.new' do
    context 'when passed a path, body and database' do
      it 'sets the database from the database argument' do
        content_item = Boombera::ContentItem.new('/foo', 'bar', :the_database)
        content_item.database.should == :the_database
      end
    end

    context 'when passed a CouchRest::Document instance' do
      it 'sets the database as the document database' do
        doc = CouchRest::Document.new(:path => '/foo', :body => 'bar')
        doc.stub!(:database => :the_document_database)
        content_item = Boombera::ContentItem.new(doc)
        content_item.database.should == :the_document_database
      end
    end
  end

  describe '#path' do
    it 'returns the path from the associated document' do
      content = Boombera::ContentItem.new('/index.html')
      content.path.should == '/index.html'
    end
  end

  describe '#body' do
    it 'returns the body from the associated document' do
      content = Boombera::ContentItem.new('/foo', 'foo bar baz')
      content.body.should == 'foo bar baz'
    end
  end

  describe '#body=' do
    let(:db) { stub(CouchRest::Database) }
    let(:content) { Boombera::ContentItem.new('/foo', 'not bar', db) }

    it 'overwrites the current contents of the document body' do
      content.body = 'bar'
      content.body.should == 'bar'
    end

    it 'sets the maps_to attribute equal to the path attribute if argument is not nil' do
      db.stub!(:view => {'rows' => [{'value' => '/foo'}]})
      content.map_to '/bar'
      content.body = 'something'
      content.maps_to.should == '/foo'
    end

    it 'does not change the maps_to attribute if the argument is nil' do
      db.stub!(:view => {'rows' => [{'value' => '/foo'}]})
      content.map_to '/bar'
      content.body = nil
      content.maps_to.should == '/bar'
    end
  end

  describe '#map_to' do
    context 'the source content item does not exist' do
      it 'raises an InvalidMapping exception' do
        db = stub(CouchRest::Database)
        db.stub!(:view => {'rows' => []})
        content = Boombera::ContentItem.new('/bar', nil, db)
        lambda { content.map_to('/foo') }.should \
          raise_error(Boombera::InvalidMapping, "Tried to map /bar to /foo, but /foo doesn't exist.")
      end
    end

    context 'the source content item is a normal content item' do
      let(:db) { stub(CouchRest::Database) }
      let(:content) { Boombera::ContentItem.new('/bar', 'foo bar', db) }

      before(:each) do
        db.should_receive(:view) \
          .with('boombera/content_map', :key => '/foo') \
          .and_return({'rows' => [{'value' => '/foo'}]})
        content.map_to '/foo'
      end

      it 'sets the maps_to attribute to the path of the source content' do
        content.maps_to.should == '/foo'
      end

      it 'sets the body attribute to nil' do
        content.body.should be_nil
      end
    end
  end
end
