module Boombera::Information #:nodoc: all
  def version
    File.read(File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'VERSION')))
  end

  def database_version(db)
    doc = current_design_doc(db)
    doc && doc['gem_version']
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
                if (doc['maps_to']) {
                  emit(doc.path, doc.maps_to);
                } else {
                  emit(doc.path, doc.path);
                }
              }
            }
            EOF
        },
        'map_references' => {
          'map' => <<-EOF
            function(doc) {
              if(doc['maps_to'] && doc.maps_to != doc.path) {
                emit(doc.maps_to, doc.path);
              }
            }
            EOF
        }
      }
    }
  end

  private

  def current_design_doc(db)
    db.get('_design/boombera')
  rescue RestClient::ResourceNotFound
    nil
  end
end
