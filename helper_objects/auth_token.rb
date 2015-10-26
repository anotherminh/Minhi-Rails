class AuthenticityToken
  attr_reader :token
  def initialize(res)
    @token = SecureRandom.urlsafe_base64(16)
    @cookie = { auth_token: @token }
    store_token(res)
  end

  def store_token(res)
    cookie = WEBrick::Cookie.new("_token_rails_lite_app", @cookie.to_json)
    cookie.path = '/'
    res.cookies << cookie
  end
end
