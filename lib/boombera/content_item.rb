class Boombera
  class ContentItem
    Result = Struct.new(:status)

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

      def exists?(db, path)
        result = db.view('boombera/content_map', :key => path)
        result['total_rows'] > 0
      end
    end
  end
end
