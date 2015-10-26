class Flash
  def initialize(req)
    @later = {}

    raw_cookie = req.cookies.find { |cook| cook.name == "_flash_rails_lite_app" }

    if raw_cookie
      @now_flash = JSON.parse(raw_cookie.value)
    else
      @now_flash = {}
    end
  end

  def [](key)
    @later[key] || @now_flash[key]
  end

  def []=(key, val)
    @later[key] = val
  end

  def now
    @now_flash
  end

  def store_flash(res)
    cookie = WEBrick::Cookie.new("_flash_rails_lite_app", @later.to_json)
    cookie.path = '/'
    res.cookies << cookie
  end
end
