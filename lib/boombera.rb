$:.unshift(File.expand_path(File.dirname(__FILE__)))
require 'couchrest'
require 'boombera/content_item'

class Boombera
  VersionMismatch = Class.new(StandardError)

  class << self
    def version
      File.read(File.expand_path(File.join(File.dirname(__FILE__), '..', 'VERSION')))
    end

    def database_version(db)
      db.get('_design/boombera')['gem_version']
    rescue RestClient::ResourceNotFound
      nil
    end

    def install_design_doc!(database)
      db = CouchRest.database!(database)
      db.save_doc(generate_design_doc)
    end

    def generate_design_doc
      {
        '_id' => '_design/boombera',
        'language' => 'javascript',
        'gem_version' => version,
        'views' => {
          'content_map' => {
            'map' => <<-EOF
              function(doc) {
                if (doc['path']) {
                  emit(doc.path, doc.path);
                }
              }
              EOF
          }
        }
      }
    end
  end

  attr_reader :db

  def initialize(database)
    @db = CouchRest.database!(database)
    check_database_version!
  end

  def put(path, body)
    ContentItem.create_or_update(db, path, body)
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
