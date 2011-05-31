require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'spec_helper'))

describe Boombera::ContentItem::MapResolver do
  describe '#resolve' do
    context 'with an existing content item' do
      it 'returns a ContentItem instance for the found document' do
        db = mock(CouchRest::Database)
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
        db = mock(CouchRest::Database)
        db.should_receive(:get) \
          .with('/foo') \
          .and_raise(RestClient::ResourceNotFound)
        Boombera::ContentItem::MapResolver.new('/foo', db).resolve.should == nil
      end
    end

    context 'with a path that maps to another content item' do
      it 'returns the mapped content item' do
        db = mock(CouchRest::Database)
        db.should_receive(:get) \
          .with('/foo') \
          .and_return({'_id' => '/foo', 'maps_to' => '/bar'})
        db.should_receive(:get) \
          .with('/bar') \
          .and_return(:a_document)
        Boombera::ContentItem.should_receive(:new).with(:a_document).and_return(:a_content_item)
        result = Boombera::ContentItem::MapResolver.new('/foo', db).resolve
        result.should == :a_content_item
      end

      it 'returns the pointer content item when passed the :resolve_map option as false' do
        db = mock(CouchRest::Database)
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
