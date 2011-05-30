require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe "The boombera CLI" do
  BOOMBERA_CLI = File.join(File.dirname(__FILE__), '..', '..', 'bin', 'boombera')

  let(:db) { CouchRest.database!('boombera_test') }

  before(:each) do
    db.delete!
    Boombera.install_design_doc!('boombera_test')
  end

  describe "put command" do
    context "when putting a new content item via argument string" do

      before(:each) do
        @output = `#{BOOMBERA_CLI} put boombera_test /foo "some content"`
        @exit_status = $?.exitstatus
      end

      it 'exits with a status code of 0' do
        @exit_status.should == 0
      end

      it 'outputs a message indicating that the content was saved' do
        @output.should == "Content Saved: /foo\n"
      end

      it 'creates the content in the couchdb server' do
        result = db.view('boombera/content_map', :key => '/foo')['rows'].first
        result.should_not be_nil
        document = db.get(result['id'])
        document['path'].should == '/foo'
        document['body'].should == 'some content'
      end
    end

    context "when updating an existing content item via argument string" do
      before(:each) do
        db.save_doc({:path => '/bar', :body => 'original content'})
        @output = `#{BOOMBERA_CLI} put boombera_test /bar "new content"`
        @exit_status = $?.exitstatus
      end

      it 'exits with a status code of 0' do
        @exit_status.should == 0
      end

      it 'outputs a message indicating that the content was saved' do
        @output.should == "Content Saved: /bar\n"
      end

      it 'updates the content in the couchdb server' do
        rows = db.view('boombera/content_map', :key => '/bar')['rows']
        rows.length.should == 1
        result = rows.first
        result.should_not be_nil
        document = db.get(result['id'])
        document['path'].should == '/bar'
        document['body'].should == 'new content'
      end
    end
  end

  describe 'get command' do
    context 'the requested content exists' do
      before(:each) do
        `#{BOOMBERA_CLI} put boombera_test /foo "some content"`
        @output = `#{BOOMBERA_CLI} get boombera_test /foo`
        @exit_status = $?.exitstatus
      end

      it 'exits with a status code of 0' do
        @exit_status.should == 0
      end

      it 'outputs the document body to STDOUT' do
        @output.should == "some content\n"
      end
    end
  end

  describe "install command" do
    before(:each) do
      db.delete!
      @output = `#{BOOMBERA_CLI} install boombera_test`
      @exit_status = $?.exitstatus
    end

    it 'exits with a status code of 0' do
      @exit_status.should == 0
    end

    it 'outputs a message indicating that the CouchDB portion of the Boombera application was installed' do
      @output.should == "The CouchDB Boombera application has been updated to " \
        + "version #{Boombera.version}\n"
    end

    it 'installs the boombera design document on the CouchDB instance' do
      design_doc = db.get('_design/boombera')
      expected = Boombera.generate_design_doc
      design_doc['gem_version'].should == expected['gem_version']
      design_doc['views'].should == expected['views']
    end
  end
end
