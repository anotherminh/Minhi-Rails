require 'active_support'
require 'active_support/core_ext'
require 'active_support/inflector'
require 'erb'
require_relative '../helper_objects/auth_token'
require_relative '../helper_objects/flash'
require_relative '../helper_objects/params'
require_relative '../helper_objects/router'
require_relative '../helper_objects/session'

class MasterController
  attr_reader :req, :res, :params

  # Setup the controller
  def initialize(req, res, route_params = {})
    @req = req
    @res = res
    @params = Params.new(req, route_params)
  end

  # Helper method to alias @already_built_response
  def already_built_response?
    @already_built_response ||= false
  end

  # Set the response status code and header
  def redirect_to(url)
    if self.already_built_response?
      raise "Cannot double render"
    else
      self.res.header["location"] = url
      self.res.status = 302
      @already_built_response = true
      session.store_session(res)
      flash.store_flash(res)
    end
  end

  # Populate the response with content.
  # Set the response's content type to the given type.
  # Raise an error if the developer tries to double render.
  def render_content(content, content_type)
    if self.already_built_response?
      raise "Cannot double render"
    else
      @res.content_type = content_type
      @res.body = content
      @already_built_response = true
      session.store_session(res)
      flash.store_flash(res)
    end
  end

  # use ERB and binding to evaluate templates
  # pass the rendered html to render_content
  def render(template_name)
    controller = self.class.to_s.underscore
    file_path = "./views/#{controller}/#{template_name}.html.erb"

    file = File.read(file_path)
    content = ERB.new(file).result(binding)

    type = "text/html"
    render_content(content, type)
  end

  # method exposing a `Session` object
  def session
    @session ||= Session.new(req)
  end

  def invoke_action(name)
    self.send(name)
  end

  def flash
    @flash ||= Flash.new(req)
  end

  def protect_from_forgery
    @auth = AuthenticityToken.new(res)
  end

  def form_auth_token
    @auth ? @auth.token : nil
  end
end
