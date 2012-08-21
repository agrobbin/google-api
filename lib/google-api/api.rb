module GoogleAPI
  class API

    FORMAT = :json

    attr_reader :access_token

    def initialize(access_token)
      @access_token = access_token
    end

    # The really important part of this parent class. The headers are injected here,
    # and the full URL is built from the ENDPOINT constant and the value passed thru
    # the URL parameter.
    #
    # The response is then returned, and appropriately parsed.
    def request(method, url = nil, args = {})
      args[:headers] = headers.merge(args[:headers] || {})
      args[:body] = args[:body].send("to_#{format}") if args[:body].is_a?(Hash)

      url.prepend(self.class::ENDPOINT) unless URI(url).scheme

      # Adopt Google's API erorr handling recommendation here:
      # https://developers.google.com/drive/manage-uploads#exp-backoff
      #
      # In essence, we try 5 times to perform the request. With each subsequent request,
      # we wait 2^n seconds plus a random number of milliseconds (no greater than 1 second)
      # until either we receive a successful response, or we run out of attempts.
      # If the Retry-After header is in the error response, we use whichever happens to be
      # greater, our calculated wait time, or the value in the Retry-After header.
      attempt = 0
      while attempt < 5
        response = access_token.send(method, url, args)
        break unless response.status >= 500
        seconds_to_wait = [((2 ** attempt) + rand), response.headers['Retry-After'].to_i].max
        attempt += 1
        puts "#{attempt.ordinalize} request attempt failed. Trying again in #{seconds_to_wait} seconds..."
        sleep seconds_to_wait
      end

      if response.body.present?
        case format
        when :json
          JSON.parse(response.body)
        when :xml
          Nokogiri::XML(response.body)
        end
      else
        response
      end
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

    private
      # Each class that inherits from this API class can have GDATA_VERSION set as a constant.
      # This is then passed on to each request if present to dictate which version of Google's
      # API we intend to use.
      def version
        self.class::GDATA_VERSION rescue nil
      end

      # By default we use JSON as the format we pass to Google and get back from Google. To override
      # this default setting, each class that inherits from this API class can have FORMAT set as
      # a constant. The only other possible value can be XML.
      def format
        raise ArgumentError, "#{self.class} has FORMAT set to #{self.class::FORMAT}, which is not :json or :xml" unless [:json, :xml].include?(self.class::FORMAT)
        self.class::FORMAT
      end

      # Build the header hash for the request. If #version is set, we pass that as GData-Version,
      # and if #format is set, we pass that as Content-Type.
      def headers
        headers = {}
        headers['GData-Version'] = version if version
        headers['Content-Type'] = case format
        when :json
          'application/json'
        when :xml
          'application/atom+xml'
        end
        return headers
      end

      def build_upload_url(url)
        path = URI(self.class::ENDPOINT).path
        "https://www.googleapis.com/upload#{path}#{url}?uploadType=resumable"
      end

  end
end
