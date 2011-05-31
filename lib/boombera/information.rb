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
        'content_paths' => {
          'map' => <<-EOF
            function(doc) {
              if (doc['type'] && doc.type == 'content_item') {
                if (doc['maps_to']) {
                  emit(doc._id, doc.maps_to);
                } else {
                  emit(doc._id, doc._id);
                }
              }
            }
            EOF
        },
        'map_references' => {
          'map' => <<-EOF
            function(doc) {
              if(doc['maps_to'] && doc.maps_to != doc._id) {
                emit(doc.maps_to, doc._id);
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
