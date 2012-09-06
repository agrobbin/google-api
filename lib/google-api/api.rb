module GoogleAPI
  class API

    attr_reader :access_token, :api, :map

    def initialize(access_token, api, map)
      @access_token = access_token
      @api = api
      @map = map
    end

    # Taking over #method_missing here allows us to chain multiple methods onto a API
    # instance. If the current place we are in the API includes this method, then let's call it!
    # If not, and there are multiple methods below this section of the API, build a new API
    # and do it all over again.
    #
    # As an example:
    #
    #   User.find(1).google.drive.files.list => we will be calling this method twice, once to find all
    #   methods within the files section of the API, and once to send a request to the #list API method,
    #   delegating to the #request method above.
    #
    #   User.find(1).google.drive.files.permissions.list => we will end up calling this method three times,
    #   until we get to the end of the chain.
    #   (Note: This method chain doesn't map to an actual Google Drive API method.)
    #
    # If the API method includes a mediaUpload key, we know that this method allows uploads, like to upload
    # a new Google Drive file. If so, we call the #upload method instead of #request.
    def method_missing(method, *args)
      api_method = map[method.to_s]
      args = args.last.is_a?(Hash) ? args.last : {} # basically #extract_options!
      methods_or_resources = api_method['methods'] || api_method['resources']
      if methods_or_resources
        API.new(access_token, api, methods_or_resources)
      else
        url, options = build_url(api_method, args)

        raise ArgumentError, ":body parameter was not passed" if !options[:body] && %w(POST PUT PATCH).include?(api_method['httpMethod'])

        send(api_method['mediaUpload'] && args[:media] ? :upload : :request, api_method['httpMethod'].downcase, url, options)
      end
    end

    private
      # A really important part of this class. The headers are injected here,
      # and the body is transformed into a JSON'd string when necessary.
      # We do exponential back-off for error responses, and return a parsed
      # response body if present, the full Response object if not.
      def request(method, url = nil, options = {})
        options[:headers] = {'Content-Type' => 'application/json'}.merge(options[:headers] || {})
        options[:body] = options[:body].to_json if options[:body].is_a?(Hash)

        # Adopt Google's API erorr handling recommendation here:
        # https://developers.google.com/drive/handle-errors#implementing_exponential_backoff
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
          response = access_token.send(method.to_sym, url, options)
          seconds_to_wait = [((2 ** attempt) + rand), response.headers['Retry-After'].to_i].max
          attempt += 1
          break if response.status < 400 || attempt == max_attempts
          GoogleAPI.logger.error "Request attempt ##{attempt} to #{url} failed for. Trying again in #{seconds_to_wait} seconds..."
          sleep seconds_to_wait
        end

        response.parsed || response
      end

      # Build a resumable upload request that then makes POST and PUT requests with the correct
      # headers for each request.
      #
      # The initial POST request initiates the upload process, passing the metadata for the file.
      # The response from the API includes a Location header telling us where to actually send the
      # media we want uploaded. The subsequent PUT request sends the media itself to the API.
      def upload(api_method, url, options = {})
        mime_type = ::MIME::Types.type_for(options[:media]).first.to_s
        file = File.read(options.delete(:media))

        options[:body][:mimeType] = mime_type
        options[:headers] = (options[:headers] || {}).merge({'X-Upload-Content-Type' => mime_type})

        response = request(api_method, url, options)

        options[:body] = file
        options[:headers].delete('X-Upload-Content-Type')
        options[:headers].merge!({'Content-Type' => mime_type, 'Content-Length' => file.bytesize.to_s})

        request(:put, response.headers['Location'], options)
      end

      # Put together the full URL we will send a request to.
      # First we join the API's base URL with the current method's path, forming the main URL.
      #
      # If the method is mediaUpload-enabled (like uploading a file to Google Drive), then we want
      # to take the path from the resumable upload protocol.
      #
      # If not, then, we are going to iterate through each of the parameters for the current method.
      # When the parameter's location is within the path, we first check that we have had that
      # option passed, and if so, substitute it in the correct place.
      # When the parameter's location is a query, we add it to our query parameters hash, provided it is present.
      # Before returning the URL and remaining options, we have to build the query parameters hash
      # into a string and append it to the end of the URL.
      def build_url(api_method, options = {})
        if api_method['mediaUpload'] && options[:media]
          # we need to do [1..-1] to remove the prepended slash
          url = GoogleAPI.discovered_apis[api]['rootUrl'] + api_method['mediaUpload']['protocols']['resumable']['path'][1..-1]
        else
          url = GoogleAPI.discovered_apis[api]['baseUrl'] + api_method['path']
          query_params = []
          api_method['parameters'].each_with_index do |(param, settings), index|
            param = param.to_sym
            case settings['location']
            when 'path'
              raise ArgumentError, ":#{param} was not passed" if settings['required'] && !options[param]
              url.sub!("{#{param}}", options.delete(param).to_s)
            when 'query'
              query_params << "#{param}=#{options.delete(param)}" if options[param]
            end
          end
          url += "?#{query_params.join('&')}" if query_params.length > 0
        end

        [url, options]
      end

  end
end
