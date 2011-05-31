class Boombera::ContentItem < CouchRest::Document
  class MapResolver
    def initialize(path, database, options = {})
      @path = path
      @database = database
      @final_attempt = options[:resolve_map] == false
    end

    def resolve
      id, maps_to = content_map
      return if id.nil?
      if @final_attempt || maps_to == @path
        Boombera::ContentItem.new(@database.get(id))
      else
        @path = maps_to
        resolve
      end
    end

    private

    def content_map
      rows = @database.view('boombera/content_map', :key => @path)['rows']
      return if rows.empty?
      match = rows.first
      [match['id'], match['value']]
    end
  end

  class << self
    def get(path, database, options = {})
      MapResolver.new(path, database, options).resolve
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

  def referenced_by
    rows = @database.view('boombera/map_references', :key => path)['rows']
    rows.map{ |row| row['value'] }.sort
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
