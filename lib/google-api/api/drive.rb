module GoogleAPI
  class Drive < API

    ENDPOINT = 'https://www.googleapis.com/drive/v2'

    # Fetch all files and folders for a particular user, returning an array of file/folder hashes.
    def all
      response = get('/files')
      response['items']
    end

    # Fetch a particular file/folder based on the ID, returning a file/folder hash.
    def find(id)
      get("/files/#{id}")
    end

    # Delegates to #find, checking if the particular file/folder exists.
    def exists?(id)
      find(id)['kind'].present?
    end

    # Create a file/folder for a particular user, returning a file/folder hash.
    # When you want to upload a file, pass a secondary parameter with the path to the file.
    def create(object, file_path = nil)
      response = if file_path
        # Upload a file
        upload('/files', object, file_path)
      else
        # Create a folder
        object[:mimeType] = 'application/vnd.google-apps.folder'
        post('/files', body: object)
      end
      response
    end

    # Destroy a particular file/folder based on the ID, returning true if successful.
    def destroy(id)
      delete("/files/#{id}")
    end

    private
      def parse_object(response)
        {
          id: response['selfLink'],
          title: response['title'],
          updated_at: DateTime.parse(response['updated']),
          details: response['details'],
          eventFeed: response['eventFeedLink']
        }
      end

  end
end
