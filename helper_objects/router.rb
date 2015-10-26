require_relative './params.rb'
require_relative '../controllers/cats_controller.rb'

class Route
  attr_reader :pattern, :http_method, :controller_class, :action_name

  def initialize(pattern, http_method, controller_class, action_name)
    @pattern = pattern
    @http_method = http_method
    @controller_class = controller_class
    @action_name = action_name
  end

  # checks if pattern matches path and method matches request method
  def matches?(req)
    method = req.request_method.downcase.to_sym
    @pattern =~ req.path && @http_method == method
  end

  # use pattern to pull out route params (save for later?)
  # instantiate controller and call controller action
  def run(req, res)
    @route_params = {}
    match_data = pattern.match(req.path)
    match_data.names.each do |name|
      @route_params[name] = match_data[name]
    end

    controller = @controller_class.new(req, res, @route_params)
    controller.invoke_action(@action_name)
  end
end

class Router
  attr_reader :routes

  def initialize
    @routes = []
  end

  # simply adds a new route to the list of routes
  def add_route(pattern, method, controller_class, action_name)
    @routes << Route.new(pattern, method, controller_class, action_name)
  end

  # evaluate the proc in the context of the instance
  # for syntactic sugar :)
  def draw(&proc)
    self.instance_eval(&proc)
  end

  # make each of these methods that
  # when called add route
  [:get, :post, :put, :delete].each do |http_method|
    define_method(http_method) do |pattern, controller_class, method|
      add_route(pattern, http_method, controller_class, method)
    end
  end

  # should return the route that matches this request
  def match(req)
    @routes.each do |route|
      return route if route.matches?(req)
    end
    nil
  end

  # either throw 404 or call run on a matched route
  def run(req, res)
    matched_route = match(req)
    my_own_params = Params.new(req)

    if matched_route && matched_route.http_method == :get
      matched_route.run(req, res)
    elsif matched_route && matched_route.http_method != :get
      token_from_cook = req.cookies.find { |cook| cook.name == "_token_rails_lite_app" }

      if token_from_cook && (my_own_params[:form_token] == JSON.parse(token_from_cook.value)['auth_token'])
        matched_route.run(req, res)
      else
        raise "ERROR: NO TOKEN"
      end
    else
      res.status = 404
    end
  end
end
