class OAuth2Response

  attr_accessor :status

  def initialize(status_code = 200)
    @status = status_code
  end

  def headers
    {}
  end

  def parsed
    fixture(:drive_files)
  end

end
