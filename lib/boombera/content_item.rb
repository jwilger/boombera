class Boombera::ContentItem < CouchRest::Document
  class << self
    def get(path, database, options = {})
      rows = database.view('boombera/content_map', :key => path)['rows']
      return nil if rows.empty?
      match = rows.first
      maps_to = match['value']
      if maps_to == path || options[:resolve_map] == false
        new(database.get(match['id']))
      else
        get(maps_to, database)
      end
    end
  end

  attr_accessor :body
  attr_reader :path, :maps_to

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

  def map_to(source_path)
    rows = @database.view('boombera/content_map', :key => source_path)['rows']
    if rows.empty?
      raise Boombera::InvalidMapping,
        "Tried to map #{path} to #{source_path}, but #{source_path} doesn't exist."
    else
      self.body = nil
      self[:maps_to] = source_path
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
    self[:maps_to] = path unless new_body.nil?
  end

  # :nodoc:
  def maps_to
    self[:maps_to]
  end
end
