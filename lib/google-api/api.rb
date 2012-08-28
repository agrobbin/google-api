module GoogleAPI
  class API

    attr_reader :access_token, :base_url

    def initialize(access_token)
      @access_token = access_token
      @data_format ||= :json
      raise ArgumentError, "#{self.class}'s data_format has been set to :#{self.class.data_format}, which is not :json or :xml" unless [:json, :xml].include?(self.class.data_format)
    end

    # The really important part of this parent class. The headers are injected here,
    # and the full URL is built from the endpoint class method or base URL
    # and the value passed thru the URL parameter.
    #
    # The response is then returned, and appropriately parsed.
    def request(method, url = nil, args = {})
      args[:headers] = headers.merge(args[:headers] || {})
      args[:body] = args[:body].send("to_#{self.class.data_format}") if args[:body].is_a?(Hash)

      url.prepend(build_endpoint) unless URI(url).scheme

      # Adopt Google's API erorr handling recommendation here:
      # https://developers.google.com/drive/manage-uploads#exp-backoff
      #
      # In essence, we try 5 times to perform the request. With each subsequent request,
      # we wait 2^n seconds plus a random number of milliseconds (no greater than 1 second)
      # until either we receive a successful response, or we run out of attempts.
      # If the Retry-After header is in the error response, we use whichever happens to be
      # greater, our calculated wait time, or the value in the Retry-After header.
      #
      # If development_mode is set to true, we only run the request once. This speeds up
      # development for those using this gem.
      attempt = 0
      max_attempts = GoogleAPI.development_mode ? 1 : 5
      while attempt < max_attempts
        response = access_token.send(method, url, args)
        seconds_to_wait = [((2 ** attempt) + rand), response.headers['Retry-After'].to_i].max
        attempt += 1
        break if response.status < 400 || attempt == max_attempts
        GoogleAPI.logger.error "#{attempt.ordinalize} request attempt to #{url} failed for. Trying again in #{seconds_to_wait} seconds..." if defined?(::Rails)
        sleep seconds_to_wait
      end

      response.parsed
    end

    # Shortcut methods to easily execute a HTTP request with any of the below HTTP verbs.
    [:get, :post, :put, :patch, :delete].each do |method|
      define_method method do |url = nil, args = {}|
        request(method, url, args)
      end
    end

    # Build a resumable upload request that then delegates to #post and #put with the correct
    # headers for each request.
    #
    # The initial POST request initiates the upload process, passing the metadata for the file.
    # The response from the API includes a Location header telling us where to actually send the
    # file we want uploaded. The subsequent PUT request sends the file itself to the API.
    def upload(url, object, file_path)
      object[:mimeType] = MIME::Types.type_for(file_path).first.to_s
      file = File.read(file_path)

      response = post(build_upload_url(url), body: object, headers: {'X-Upload-Content-Type' => object[:mimeType]})
      put(response.headers['Location'], body: file, headers: {'Content-Type' => object[:mimeType], 'Content-Length' => file.bytesize.to_s})
    end

    class << self

      # This class-level method is available to easily add a sub-API of sorts to an API. Look at
      # GoogleAPI::Drive for an example.
      def inherited_apis(*apis)
        apis.each do |api|
          define_method api do |id|
            "#{self.class}::#{api.capitalize}".constantize.new(access_token, id)
          end
        end
      end

      # Build the API setting methods for easy configuration of an API's connection settings.
      [:data_format, :endpoint, :version].each do |setting|
        define_method setting do |value = nil|
          if value.nil?
            instance_variable_get("@#{setting}")
          else
            instance_variable_set("@#{setting}", value)
          end
        end
      end

    end

    private
      # Build the header hash for the request. If the class's version is set, we pass that as GData-Version,
      # and if the class's data_format is set, we pass that as Content-Type.
      def headers
        headers = {}
        headers['GData-Version'] = self.class.version if self.class.version
        headers['Content-Type'] = case self.class.data_format
        when :json
          'application/json'
        when :xml
          'application/atom+xml'
        end
        return headers
      end

      # Choose the endpoing URL. If a base_url is set, use that, otherwise, fall back to the endpoint setting.
      def build_endpoint
        base_url || self.class.endpoint
      end

      # Create the upload URL for any particular API's upload mechanism from the endpoint/base URL, appending and
      # prepending the correct URL parts.
      def build_upload_url(url)
        path = URI(build_endpoint).path
        "https://www.googleapis.com/upload#{path}#{url}?uploadType=resumable"
      end

  end
end
