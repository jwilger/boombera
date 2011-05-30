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
      design = design_doc
      existing = db.documents(:key => '_design/boombera')['rows'].first
      design['_rev'] = existing['value']['rev'] unless existing.nil?
      db.save_doc(design)
    end

    def design_doc
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

  def initialize(database_name)
    @db = CouchRest.database!(database_name)
    check_database_version!
  end

  def put(path, body)
    content_item = get(path) || ContentItem.new(:path => path, :database => db)
    content_item.body = body
    content_item.save
  end

  def get(path)
    ContentItem.get(path, db)
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
