module Boombera::Information
  def version
    File.read(File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'VERSION')))
  end

  def database_version(db)
    doc = current_design_doc(db)
    doc && doc['gem_version']
  end

  def install_design_doc!(database)
    db = CouchRest.database!(database)
    existing = current_design_doc(db)
    design = design_doc
    design['_rev'] = existing['_rev'] unless existing.nil?
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

  private

  def current_design_doc(db)
    db.get('_design/boombera')
  rescue RestClient::ResourceNotFound
    nil
  end
end
