class Params
  # use your initialize to merge params from
  # 1. query string
  # 2. post body
  # 3. route params
  #
  # You haven't done routing yet; but assume route params will be
  # passed in as a hash to `Params.new` as below:
  def initialize(req, route_params = {})
    query_str = req.query_string
    if query_str
      query_params = parse_www_encoded_form(req.query_string)
    else
      query_params = {}
    end

    post_body = req.body
    if post_body
      body_params = parse_www_encoded_form(req.body)
    else
      body_params = {}
    end

    if route_params
      @params = route_params.merge(query_params).merge(body_params)
    else
      @params = query_params.merge(body_params)
    end
  end

  def [](key)
    @params[key.to_s] || @params[key.to_sym]
  end

  # this will be useful if we want to `puts params` in the server log
  def to_s
    @params.to_s
  end

  class AttributeNotFoundError < ArgumentError; end;

  private
  # this should return deeply nested hash
  # argument format
  # user[address][street]=main&user[address][zip]=89436
  # should return
  # { "user" => { "address" => { "street" => "main", "zip" => "89436" } } }
  def parse_www_encoded_form(www_encoded_form)
    ary = URI.decode_www_form(www_encoded_form)
    hash = {}
    ary.each do |k_vpair|
      keys = parse_key(k_vpair[0])
      value = k_vpair[1]
      new_hash = build_nested_hash({}, keys, value)
      hash = deep_merge(hash, new_hash)
    end
    hash
  end

  def build_nested_hash(hash, keys, value)
    if keys.count == 1
      hash[keys.shift] = value
    else
      hash[keys.shift] = build_nested_hash({}, keys, value)
    end
    hash
  end

  def deep_merge(hash1, hash2)
    merged = hash1
    hash2.each do |key, value|
      unless hash1.keys.include?(key)
        merged[key] = hash2[key]
      else
        merged[key] = deep_merge(hash1[key], hash2[key])
      end
    end
    merged
  end

  # this should return an array
  # user[address][street] should return ['user', 'address', 'street']
  def parse_key(key)
    key.split(/\]\[|\[|\]/)
  end
end
