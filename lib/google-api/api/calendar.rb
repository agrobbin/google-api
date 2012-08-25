# For Google's API reference:
# https://developers.google.com/google-apps/calendar/v3/reference/

module GoogleAPI
  class Calendar < API

    endpoint 'https://www.googleapis.com/calendar/v3'
    data_format :json

    # Fetch all calendars for a particular user, returning an array of calendar hashes.
    def all
      get('/users/me/calendarList')
    end

    # Fetch a particular calendar based on the ID, returning a calendar hash.
    def find(id)
      get("/users/me/calendarList/#{id}")
    end

    # Delegates to #find, checking if the particular calendar exists.
    def exists?(id)
      find(id)['error'].blank?
    end

    # Create a calendar for a particular user, returning a calendar hash.
    def create(calendar)
      post('/calendars', body: calendar)
    end

    # Destroy a particular calendar based on the ID, returning true if successful.
    def destroy(id)
      delete("/calendars/#{id}")
    end

    private
      def parse_calendar(response)
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
