class Boombera::ContentItem < CouchRest::Document
  class << self
    def get(path, database)
      rows = database.view('boombera/content_map', :key => path)['rows']
      return nil if rows.empty?
      id = rows.first['id']
      new(database.get(id))
    end
  end

  attr_accessor :body
  attr_reader :path

  def initialize(doc_or_path, body = nil, database = nil)
    case doc_or_path
    when CouchRest::Document
      @database = doc_or_path.database
      super(doc_or_path)
    when String
      @database = database
      super(:path => doc_or_path, :body => body)
    else
      raise ArgumentError, "doc_or_path must either be an instance of CouchRest::Document or a String"
    end
  end

  # :nodoc:
  def path
    self[:path]
  end

  # :nodoc:
  def body
    self[:body]
  end

  # :nodoc:
  def body=(new_body)
    self[:body] = new_body
  end
end
