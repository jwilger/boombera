# ContentItem is a specialization of CouchRest::Document that adds
# content-mapping semantics and method-based access to the attributes that
# Boombera knows about.
class Boombera::ContentItem < CouchRest::Document
  # The actual content that is being stored
  attr_accessor :body

  # The path used to access the ContentItem, it is stored as the '_id' attribute
  # in CouchDB
  attr_reader :path

  def self.get(path, db)
    doc = get_pointer(path, db)
    until doc.nil? || doc.resolved?
      doc = get_pointer(doc.maps_to, db)
    end
    doc
  end

  def self.get_pointer(path, db)
    Boombera::ContentItem.new(db.get(path))
  rescue RestClient::ResourceNotFound
    nil
  end

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

  def resolved?
    path == maps_to
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
