# For Google's API reference:
# https://developers.google.com/drive/v2/reference

module GoogleAPI
  class Drive < API

    endpoint 'https://www.googleapis.com/drive/v2'
    data_format :json
    inherited_apis :permission

    # Fetch all files and folders for a particular user, returning an array of file/folder hashes.
    def all
      get('/files')
    end

    # Fetch a particular file/folder based on the ID, returning a file/folder hash.
    def find(id)
      get("/files/#{id}")
    end

    # Based on the query parameters passed to this method, we chain them together with ' and '
    # and then encode the search query, passing it as the :q URL parameter to the list URL of
    # Google Drive. At least one query parameter must be passed.
    #
    # To read more about what format the query parameters should be passed as, read Google's
    # "Searching for Files" API page:
    #
    #   https://developers.google.com/drive/search-parameters
    #
    # We encode the parameters for you, so you can pass unencoded text to this method.
    def search(*query_params)
      raise ArgumentError, "You must pass at least one query parameter to this method." if query_params.empty?

      get("/files?q=#{URI.encode(query_params.join(' and '))}")
    end

    # Delegates to #find, checking if the particular file/folder exists.
    def exists?(id)
      find(id)['error'].blank?
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

    def update(id, object)
      patch("/files/#{id}", body: object)
    end

    # Destroy a particular file/folder based on the ID, returning true if successful.
    def destroy(id)
      delete("/files/#{id}")
    end

    # Move a file/folder to a new location. If folder_ids are passed, moves the
    # file/folder to be in those folders. If no folder_ids are passed, moves the
    # file/folder to the root folder (which is fetched via the /about URL).
    def move(id, *folder_ids)
      folder_ids << about['rootFolderId'] if folder_ids.empty?
      folder_ids.collect {|folder| {id: folder}}
      update(id, {parents: new_locations})
    end

    def about
      get('/about')
    end

  end
end
