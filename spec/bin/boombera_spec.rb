require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe "The boombera CLI" do
  BOOMBERA_CLI = File.join(File.dirname(__FILE__), '..', '..', 'bin', 'boombera')

  let(:db) { CouchRest.database!('http://127.0.0.1:5984/boombera_test') }

  before(:each) do
    db.delete!
    db.create!
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

      it 'outputs a message indicating that the content was created' do
        @output.should == "Content Created: /foo\n"
      end

      it 'creates the content in the couchdb server' do
        result = db.documents['rows'].first
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

      it 'outputs a message indicating that the content was updated' do
        @output.should == "Content Updated: /bar\n"
      end

      it 'updates the content in the couchdb server' do
        rows = db.documents['rows']
        rows.length.should == 1
        result = rows.first
        result.should_not be_nil
        document = db.get(result['id'])
        document['path'].should == '/bar'
        document['body'].should == 'new content'
      end
    end
  end
end
