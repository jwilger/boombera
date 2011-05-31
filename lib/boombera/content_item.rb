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

  def initialize(pkeys = {})
    @database = if pkeys.respond_to?(:database)
                  pkeys.database
                else
                  pkeys.delete(:database)
                end
    super
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
