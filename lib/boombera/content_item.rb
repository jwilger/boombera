# ContentItem is a specialization of CouchRest::Document that adds
# content-mapping semantics and method-based access to the attributes that
# Boombera knows about.
class Boombera::ContentItem < CouchRest::Document
  class MapResolver #:nodoc: all
    def initialize(path, database, options = {})
      @path = path
      @database = database
      @final_attempt = options[:resolve_map] == false
    end

    def resolve
      doc = @database.get(@path)
      if (doc['_id'] == doc['maps_to']) || @final_attempt
        return Boombera::ContentItem.new(doc)
      else
        @path = doc['maps_to']
        resolve
      end
    rescue RestClient::ResourceNotFound
      return nil
    end
  end

  # The actual content that is being stored
  attr_accessor :body

  # The path used to access the ContentItem, it is stored as the '_id' attribute
  # in CouchDB
  attr_reader :path

  def initialize(doc_or_path, body = nil, database = nil) #:nodoc:
    case doc_or_path
    when CouchRest::Document
      @database = doc_or_path.database
      super(doc_or_path)
    when String
      @database = database
      super('_id' => doc_or_path, 'body' => body)
    else
      raise ArgumentError, "doc_or_path must either be an instance of CouchRest::Document or a String"
    end
  end

  def map_to(source_path) #:nodoc:
    rows = @database.view('boombera/content_paths', :key => source_path)['rows']
    if rows.empty?
      raise Boombera::InvalidMapping,
        "Tried to map #{path} to #{source_path}, but #{source_path} doesn't exist."
    else
      self.body = nil
      self['maps_to'] = source_path
    end
  end

  # Returns the paths that are aliased to this ContentItem
  def referenced_by
    rows = @database.view('boombera/map_references', :key => path)['rows']
    rows.map{ |row| row['value'] }.sort
  end

  def save(*args)
    self['maps_to'] = maps_to
    self['type'] = 'content_item'
    super
  end

  def maps_to #:nodoc:
    return path unless body.nil?
    self['maps_to'] || path
  end

  def path #:nodoc:
    self['_id']
  end

  def body #:nodoc:
    self['body']
  end

  def body=(new_body) #:nodoc:
    self['body'] = new_body
  end
end
