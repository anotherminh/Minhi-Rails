#Minhi-Rails

A Rails-inspired web application (MVC) framework that I built from scratch in Ruby.

#Features
- [ ] Mounts local server using WEBrick
- [ ] Controller class that can redirect and render HTML templates given HTTP requests and response objects as inputs
- [ ] Store and read cookies in the browser (for session cookies and flashes)
- [ ] Params class that parses params from the matched route, query string, and request body.
- [ ] Router class that handles incoming requests by instantiating a controller and invoking the matched controller action.
- [ ] An AuthenticityToken class for CSRF protection.  It generates a SecureRandom string, stores it in an auth_token cookie, and checks for this cookie when the router is handling a non-GET request.

#Instructions
To use this library, simply download it as a .zip file on your local machine, then navigate to the
root directory and run:

`ruby server.rb`

The example website that comes with this repo is a cat-tracker site, where you can keep track
of your cats by adding them to the database. Making your own website is easy---any models, controllers, or database (db) should go into their respective folder, and then you can draw your routes in the server.rb file.
Any CSS Styling can be included by linking to the file from your view (html), like so:

`<link rel="stylesheet" href="[relative_path_to_your_css_file]">`


#Code Highlights
I used recursion to build nested params from query strings. I used URI to first parse
the query string into 2D array, like so:

`"user[address][street]=main&user[address][zip]=89436" => [["user[address][street]", "main"], ["user[address][zip]", "89436"]]`

Then, as I iterate through each element in this array,
I call on a helper function that retrieves all the nested keys.
Given "['user[address][street]', 'main']", it
should return ['user', 'address', 'street'].

<code>
  def parse_key(key)
    key.split(/\]\[|\[|\]/)
  end
</code>

The fun part is when I use recursion to build the nested hash,
using the flattened keys and value:

<code>
def build_nested_hash(hash, keys, value)
  if keys.count == 1
    hash[keys.shift] = value
  else
    hash[keys.shift] = build_nested_hash({}, keys, value)
  end
  hash
end
</code>

So, each element gets their own nested hash, and is then deep-merged together
to create the hash for the entire query string:

<code>
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
</code>
