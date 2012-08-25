# For Google's API reference:
# https://developers.google.com/drive/v2/reference/permissions

module GoogleAPI
  class Drive
    class Permission < API

      endpoint 'https://www.googleapis.com/drive/v2'
      data_format :json

      def initialize(access_token, id)
        super(access_token)
        @base_url = "#{self.class.endpoint}/files/#{id}"
      end

      # Fetch all files and folders for a particular user, returning an array of file/folder hashes.
      def all
        get('/permissions')
      end

      # Fetch a particular file/folder based on the ID, returning a file/folder hash.
      def find(id)
        get("/permissions/#{id}")
      end

      # Delegates to #find, checking if the particular permission exists.
      def exists?(id)
        find(id)['error'].blank?
      end

      # Create a file/folder for a particular user, returning a file/folder hash.
      # When you want to upload a file, pass a secondary parameter with the path to the file.
      #
      # Passing true as the secondary parameter will send notification emails to the
      # appropriate person.
      def create(permission, sendNotificationEmails = false)
        post("/permissions?sendNotificationEmails=#{sendNotificationEmails}", body: permission)
      end

      def update(id, permissions)
        patch("/permissions/#{id}", body: permission)
      end

      # Destroy a particular file/folder based on the ID, returning true if successful.
      def destroy(id)
        delete("/permission/#{id}")
      end

    end
  end
end
