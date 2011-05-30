require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'spec_helper'))

describe Boombera::ContentItem do
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
        result = Boombera::ContentItem.get('/foo', db)
        result.path.should == '/foo'
        result.body.should == 'bar'
      end
    end
  end

  describe '.new' do
    context 'when passed a plain hash' do
      it 'sets the database from the params hash' do
        content_item = Boombera::ContentItem.new(:path => '/foo',
                                                 :body => 'bar',
                                                 :database => :the_database)
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
      content = Boombera::ContentItem.new('path' => '/index.html')
      content.path.should == '/index.html'
    end
  end

  describe '#body' do
    it 'returns the body from the associated document' do
      content = Boombera::ContentItem.new('body' => 'foo bar baz')
      content.body.should == 'foo bar baz'
    end
  end

  describe '#body=' do
    it 'overwrites the current contents of the document body' do
      content = Boombera::ContentItem.new('body' => 'foo')
      content.body = 'bar'
      content.body.should == 'bar'
    end
  end
end
