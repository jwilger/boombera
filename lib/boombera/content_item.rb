class Boombera
  class ContentItem
    Result = Struct.new(:status, :content_item)

    class << self
      def create_or_update(db, path, body)
        if exists?(db, path)
          update(db, path, body)
        else
          create(db, path, body)
        end
      end

      def create(db, path, body)
        db.save_doc({:path => path, :body => body})
        Result.new(:created)
      end

      def update(db, path, body)
        result = get(db, path)
        document = result.content_item
        document.body = body
        document.save
      end

      def exists?(db, path)
        (content_item_id_for(db, path) || false) && true
      end

      def get(db, path)
        doc = db.get(content_item_id_for(db, path))
        Result.new(:success, ContentItem.new(doc))
      end

      private

      def content_item_id_for(db, path)
        rows = db.view('boombera/content_map', :key => path)['rows']
        return nil if rows.empty?
        rows.first['id']
      end
    end

    def initialize(doc)
      @doc = doc
    end

    def path
      @doc['path']
    end

    def body
      @doc['body']
    end

    def body=(new_body)
      @doc['body'] = new_body
    end

    def save
      @doc.save
      Result.new(:updated)
    end
  end
end
