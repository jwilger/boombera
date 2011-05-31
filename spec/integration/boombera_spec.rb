require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe 'The Boombera library:' do
  let(:db_name) { 'boombera_test' }
  let(:db) { CouchRest.database!(db_name) }

  let(:boombera) do
    Boombera.install_design_doc!(db_name)
    Boombera.new(db_name)
  end

  before(:each) do
    db.delete!
    db.create!
  end

  describe 'installing and updating the couchdb design document' do
    context 'on a new boombera database' do
      it 'publishes Boombera.design_doc to _design/boombera' do
        Boombera.install_design_doc!(db_name)
        design = db.get('_design/boombera')
        %w(_id gem_version views).each do |key|
          design[key].should == Boombera.design_doc[key]
        end
      end
    end

    context 'on an existing boombera database' do
      it 'updates Boombera.design_doc to _design/boombera' do
        db.save_doc({'_id' => '_design/boombera'})
        Boombera.install_design_doc!(db_name)
        design = db.get('_design/boombera')
        %w(_id gem_version views).each do |key|
          design[key].should == Boombera.design_doc[key]
        end
      end
    end
  end

  describe 'connecting to the database' do
    context 'when the design document does not exist' do
      it 'raises a VersionMismatch exception' do
        lambda { Boombera.new(db_name) }.should \
          raise_error(Boombera::VersionMismatch, "Database does not specify a Boombera version")
      end
    end

    context 'when the design document does not have a gem_version specified' do
      it 'raises a VersionMismatch exception' do
        db.save_doc({'_id' => '_design/boombera'})
        lambda { Boombera.new(db_name) }.should \
          raise_error(Boombera::VersionMismatch, "Database does not specify a Boombera version")
      end
    end

    context 'when the design document does not match the version of the library being used' do
      it 'raises a VersionMismatch exception' do
        db.save_doc({'_id' => '_design/boombera', 'gem_version' => '0.0.0'})
        lambda { Boombera.new(db_name) }.should \
          raise_error(Boombera::VersionMismatch, "Database expects Boombera 0.0.0")
      end
    end
  end

  describe 'putting content in the database' do
    it 'saves content to a new path' do
      boombera.put('/foo', 'foo bar baz')
      results = db.view('boombera/content_map', :key => '/foo')['rows']
      results.length.should == 1
      document = db.get(results.first['id'])
      document['path'].should == '/foo'
      document['body'].should == 'foo bar baz'
    end

    it 'saves content to an existing path' do
      boombera.put('/foo', 'foo bar baz')
      boombera.put('/foo', 'the new content')
      results = db.view('boombera/content_map', :key => '/foo')['rows']
      results.length.should == 1
      document = db.get(results.first['id'])
      document['path'].should == '/foo'
      document['body'].should == 'the new content'
    end

    it 'turns a pointer into a content item' do
      boombera.put('/foo', 'foo bar baz')
      boombera.map('/bar', '/foo')
      boombera.put('/bar', 'the new content')
      results = db.view('boombera/content_map', :key => '/bar')['rows']
      results.length.should == 1
      document = db.get(results.first['id'])
      document['path'].should == '/foo'
      document['body'].should == 'the new content'
      document['points_to'].should be_nil
    end
  end

  describe 'mapping content aliases' do
    it 'creates a pointer from a path to another path' do
      boombera.put('/foo', 'foo bar baz')
      boombera.map('/bar', '/foo')
      results = db.view('boombera/content_map', :key => '/bar')['rows']
      results.length.should == 1
      map_item = results.first
      map_item.value.should == '/foo'
    end

    it 'updates a pointer from a path to another path' do
      boombera.put('/foo', 'foo bar baz')
      boombera.put('/spam', 'ham spam can')
      boombera.map('/bar', '/foo')
      boombera.map('/bar', '/spam')
      results = db.view('boombera/content_map', :key => '/bar')['rows']
      results.length.should == 1
      map_item = results.first
      map_item.value.should == '/spam'
    end

    it 'turns a content item into a pointer' do
      boombera.put('/foo', 'foo bar baz')
      boombera.put('/bar', 'some old bar content')
      boombera.map('/bar', '/foo')
      results = db.view('boombera/content_map', :key => '/bar')['rows']
      results.length.should == 1
      map_item = results.first
      map_item.value.should == '/spam'
      doc = db.get(map_item['id'])
      doc['body'].should be_nil
    end
  end

  describe 'getting content from the database' do
    it 'gives you nil if the content is not there' do
      boombera.get('/not_there').should == nil
    end

    it 'gives you a ContentItem if the content is there' do
      db.save_doc({'path' => '/index', 'body' => 'Hello, World!'})
      result = boombera.get('/index')
      result.path.should == '/index'
      result.body.should == 'Hello, World!'
    end

    it 'gives you the resulting ContentItem when a pointer is requested' do
      boombera.put('/foo', 'some content')
      boombera.map('/bar', '/foo')
      result = boombera.get('/bar')
      result.path.should == '/foo'
      result.body.should == 'some content'
    end
  end

  describe 'working with ContentItem' do
    it 'lets you save changes' do
      boombera.put('/foo', 'some content')
      content = boombera.get('/foo')
      content.body = 'new content'
      content.save
      boombera.get('/foo').body.should == 'new content'
    end

    it 'knows which pointers reference it' do
      boombera.put('/foo', 'some content')
      boombera.map('/zurg', '/foo')
      boombera.map('/bar', '/foo')
      boombera.map('/bar/baz', '/foo')
      content = boombera.get('/foo')
      content.referenced_by.should == ['/bar', '/bar/baz', '/zurg']
    end
  end
end
