class User

  attr_accessor :authenticated, :expires_at

  def self.oauthable
    true
  end

  def id
    1
  end

  def oauth_hash
    {
      access_token: authenticated ? 'test access token' : nil,
      refresh_token: authenticated ? 'test refresh token' : nil,
      expires_at: expires_at || (authenticated ? Time.now + 3600 : nil)
    }
  end

  def update_access_token!(access_token)
  end

  def google
  end

end