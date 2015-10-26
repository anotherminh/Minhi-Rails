require 'json'
require 'webrick'

class Session
  # find the cookie for this app
  # deserialize the cookie into a hash
  def initialize(req)
    raw_cookie = req.cookies.find { |cook| cook.name == "_rails_lite_app" } #session_token
    if raw_cookie
      @cookie = JSON.parse(raw_cookie.value)
    else
      @cookie = {}
    end
  end

  def [](key)
    @cookie[key]
  end

  def []=(key, val)
    @cookie[key] = val
  end

  # serialize the hash into json and save in a cookie
  # add to the responses cookies
  def store_session(res)
    res.cookies << WEBrick::Cookie.new("_rails_lite_app", @cookie.to_json)
  end
end
