$:.unshift(File.expand_path(File.dirname(__FILE__)))
require 'couchrest'

# This is the main interface to the Boombera content repository.
#
# == Usage examples:
#
#   # install/update the CouchDB design document
#   Boombera.install_design_doc!('my_database')
#
#   # connect to the database
#   boombera = Boombera.new('my_database')
#   
#   # put and get some content
#   boombera.put('/hello', 'Hello, world!')
#   #=> true
#
#   content = boombera.get('/hello')
#   content.body
#   #=> 'Hello, world!'
#
#   # update the content via the ContentItem
#   content.body = 'Hello, friends!'
#   content.save
#   #=> true
#
#   # update the content without an object
#   boombera.put('/hello', 'Hello, everyone!')
#   content = boombera.get('/hello')
#   content.body
#   #=> 'Hello, everyone!'
#
#   # map an alias to the content
#   boombera.map('/hi', '/hello')
#   content = boombera.get('/hi')
#   content.path
#   #=> '/hello'
#
#   content.body
#   #=> 'Hello, everyone!'
#
#   # override the map with some different content
#   boombera.put('/hi', "G'day, mate!")
#   content = boombera.get('/hi')
#   content.path
#   #=> '/hi'
#
#   content.body
#   #=> "G'day, mate!"
#
#   content = boombera.get('/hello')
#   content.path
#   #=> '/hello'
#
#   content.body
#   #=> 'Hello, everyone!'
class Boombera
  require 'boombera/content_item'
  require 'boombera/information'

  # Exception is raised when connecting to a Boombera CouchDB database that
  # expects a different version of the Boombera library than the one currently
  # being used.
  class VersionMismatch < StandardError; end

  # Exception is raised when attempting to create a content mapping and the
  # source document doesn't exist.
  class InvalidMapping < RuntimeError; end

  extend Boombera::Information

  # The CouchRest::Database instance
  attr_reader :database

  # Connects to the CouchDB server and verifies the database version.
  # 
  # +database_name+:: can be either a full url to a CouchDB server and database
  # (\http://example.com:5984/my_database) or it can be just the database name
  # itself (my_database). The latter will connect to the database at
  # \http://127.0.0.1:5984.
  #
  # raises:: VersionMismatch
  def initialize(database_name)
    @database = CouchRest.database!(database_name)
    check_database_version!
  end

  # Installs the CouchDB design document for this version of the library in the
  # specified database!
  #
  # *WARNING*:: This will overwrite the current design document and prevent
  # applications that are using a different version of the Boombera library from
  # accessing the database. This change will be replicated along with everything
  # else in your database.
  # 
  # +database_name+:: can be either a full url to a CouchDB server and database
  # (\http://example.com:5984/my_database) or it can be just the database name
  # itself (my_database). The latter will connect to the database at
  # \http://127.0.0.1:5984.
  def self.install_design_doc!(database)
    db = CouchRest.database!(database)
    existing = current_design_doc(db)
    design = design_doc
    design['_rev'] = existing['_rev'] unless existing.nil?
    db.save_doc(design)
  end

  # Creates or updates the content stored at +path+ with +body+.
  #
  # +body+:: can be # any object that can convert to JSON.
  # +path+:: should be a String with /-separated tokens (i.e. "/foo/bar/baz").
  def put(path, body)
    content_item = ContentItem.get_pointer(path, database)  \
      and content_item.body = body
    content_item ||= ContentItem.new(path, body, database)
    content_item.save
  end

  # Returns the ContentItem associated with the specified path or +nil+ if none
  # is found. If +path+ is mapped to another ContentItem, the resolved
  # ContentItem will be returned.
  def get(path)
    ContentItem.get(path, database)
  end

  # Creates a content mapping so that two paths can reference the same content
  # without needing to store that content twice.
  #
  # +path+:: the new alias path for the ContentItem
  # +source_path+:: the path of the ContentItem that should be returned for
  # requests to +path+. This path *must* point to an existing ContentItem.
  # 
  # raises:: InvalidMapping
  def map(path, source_path)
    content_map = ContentItem.get_pointer(path, database) \
      || ContentItem.new(path, nil, database)
    content_map.map_to source_path
    content_map.save
  end

  private
  def check_database_version!
    database_version = Boombera.database_version(database)
    unless Boombera.version == database_version
      msg = if database_version.nil?
              "Database does not specify a Boombera version"
            else
              "Database expects Boombera #{database_version}"
            end
      raise VersionMismatch, msg
    end
  end
end
