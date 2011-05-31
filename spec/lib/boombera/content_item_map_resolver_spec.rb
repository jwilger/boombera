require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'spec_helper'))

describe Boombera::ContentItem::MapResolver do
  describe '#resolve' do
    context 'with an existing content item' do
      it 'returns a ContentItem instance for the found document' do
        view_result = {'rows' => [{'id' => '/foo', 'value' => '/foo'}]}
        db = mock(CouchRest::Database)
        db.should_receive(:view) \
          .with('boombera/content_map', :key => '/foo') \
          .and_return(view_result)
        db.should_receive(:get) \
          .with('/foo') \
          .and_return(:a_document)
        Boombera::ContentItem.should_receive(:new).with(:a_document).and_return(:a_content_item)
        result = Boombera::ContentItem::MapResolver.new('/foo', db).resolve
        result.should == :a_content_item
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
        map_view_result = {'rows' => [{'id' => '/foo', 'value' => '/bar'}]}
        content_view_result = {'rows' => [{'id' => '/bar', 'value' => '/bar'}]}
        db = mock(CouchRest::Database)
        db.should_receive(:view) \
          .with('boombera/content_map', :key => '/foo') \
          .and_return(map_view_result)
        db.should_receive(:view) \
          .with('boombera/content_map', :key => '/bar') \
          .and_return(content_view_result)
        db.should_receive(:get) \
          .with('/bar') \
          .and_return(:a_document)
        Boombera::ContentItem.should_receive(:new).with(:a_document).and_return(:a_content_item)
        result = Boombera::ContentItem::MapResolver.new('/foo', db).resolve
        result.should == :a_content_item
      end

      it 'returns the pointer content item when passed the :resolve_map option as false' do
        map_view_result = {'rows' => [{'id' => '/foo', 'value' => '/bar'}]}
        db = mock(CouchRest::Database)
        db.should_receive(:view) \
          .with('boombera/content_map', :key => '/foo') \
          .and_return(map_view_result)
        db.should_receive(:get) \
          .with('/foo') \
          .and_return(:a_document)
        Boombera::ContentItem.should_receive(:new).with(:a_document).and_return(:a_content_item)
        result = Boombera::ContentItem::MapResolver.new('/foo', db, :resolve_map => false).resolve
        result.should == :a_content_item
      end
    end
  end
end
