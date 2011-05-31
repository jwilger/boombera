$:.unshift(File.expand_path(File.dirname(__FILE__)))
require 'couchrest'

# Boombera constant is defined first as `Class.new` so that the definitions in
# the required files can use `class Boombera::Whatever` even with the `require`
# statements appearing before the actual class definition.
Boombera = Class.new

require 'boombera/content_item'
require 'boombera/information'

class Boombera
  VersionMismatch = Class.new(StandardError)
  InvalidMapping = Class.new(RuntimeError)

  extend Boombera::Information

  attr_reader :db

  def initialize(database_name)
    @db = CouchRest.database!(database_name)
    check_database_version!
  end

  def put(path, body)
    content_item = get(path) and content_item.body = body
    content_item ||= ContentItem.new(path, body, db)
    content_item.save
  end

  def get(path)
    ContentItem.get(path, db)
  end

  def map(path, source_path)
    content_map = get(path) || ContentItem.new(path, nil, db)
    content_map.map_to source_path
    content_map.save
  end

  private

  def check_database_version!
    database_version ||= Boombera.database_version(db)
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
