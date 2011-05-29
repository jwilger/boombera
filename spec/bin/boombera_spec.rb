require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe "The boombera CLI" do
  BOOMBERA_CLI = File.join(File.dirname(__FILE__), '..', '..', 'bin', 'boombera')

  describe "put command" do
    context "when putting a new content item via argument string" do
      before(:each) do
        db = CouchRest.database!('http://127.0.0.1:5984/boombera_test')
        db.delete!
        @output = `#{BOOMBERA_CLI} put boombera_test /foo "some content"`
        @exit_status = $?.exitstatus
      end

      it 'exits with a status code of 0' do
        @exit_status.should == 0
      end

      it 'outputs a message indicating that the content was created' do
        @output.should == "Content Created: /foo\n"
      end

      it 'stores the content in the couchdb server' do
        db = CouchRest.database!('http://127.0.0.1:5984/boombera_test')
        result = db.view('boombera/content', :key => '/foo').rows.first
        result.body.should == "some content"
      end
    end
  end
end
