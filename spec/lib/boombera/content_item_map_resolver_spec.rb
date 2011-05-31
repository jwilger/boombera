require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'spec_helper'))

describe Boombera::ContentItem::MapResolver do
  describe '#resolve' do
    context 'with an existing content item' do
      it 'returns a ContentItem instance for the found document' do
        view_result = {'rows' => [{'id' => '123', 'value' => '/foo'}]}
        db = mock(CouchRest::Database)
        db.should_receive(:view) \
          .with('boombera/content_map', :key => '/foo') \
          .and_return(view_result)
        db.should_receive(:get) \
          .with('123') \
          .and_return(CouchRest::Document.new('path' => '/foo', 'body' => 'bar'))
        result = Boombera::ContentItem::MapResolver.new('/foo', db).resolve
        result.path.should == '/foo'
        result.body.should == 'bar'
      end
    end

    context 'with a non-existant content item' do
      it 'returns nil' do
        view_result = {'rows' => []}
        db = mock(CouchRest::Database)
        db.should_receive(:view) \
          .with('boombera/content_map', :key => '/foo') \
          .and_return(view_result)
        Boombera::ContentItem::MapResolver.new('/foo', db).resolve.should == nil
      end
    end

    context 'with a path that maps to another content item' do
      it 'returns the mapped content item' do
        map_view_result = {'rows' => [{'id' => '123', 'value' => '/bar'}]}
        content_view_result = {'rows' => [{'id' => '456', 'value' => '/bar'}]}
        db = mock(CouchRest::Database)
        db.should_receive(:view) \
          .with('boombera/content_map', :key => '/foo') \
          .and_return(map_view_result)
        db.should_receive(:view) \
          .with('boombera/content_map', :key => '/bar') \
          .and_return(content_view_result)
        db.should_receive(:get) \
          .with('456') \
          .and_return(CouchRest::Document.new('path' => '/bar', 'body' => 'bar'))
        result = Boombera::ContentItem::MapResolver.new('/foo', db).resolve
        result.path.should == '/bar'
        result.body.should == 'bar'
      end

      it 'returns the pointer content item when passed the :resolve_map option as false' do
        map_view_result = {'rows' => [{'id' => '123', 'value' => '/bar'}]}
        db = mock(CouchRest::Database)
        db.should_receive(:view) \
          .with('boombera/content_map', :key => '/foo') \
          .and_return(map_view_result)
        db.should_receive(:get) \
          .with('123') \
          .and_return(CouchRest::Document.new('path' => '/foo', 'maps_to' => '/bar'))
        result = Boombera::ContentItem::MapResolver.new('/foo', db, :resolve_map => false).resolve
        result.path.should == '/foo'
        result.maps_to.should == '/bar'
      end
    end
  end
end
