require_relative './MasterController'
require_relative '../models/cat'
class CatsController < MasterController
  def create
    protect_from_forgery
    @cat = Cat.new(params["cat"])
    if @cat.save
      flash['notice'] = ["Cat saved"]
      redirect_to("/cats")
    else
      flash.now['notice'] = ["Failed to save."]
      render :new
    end
  end

  def index
    protect_from_forgery
    @cats = Cat.all
    render :index
  end

  def new
    protect_from_forgery
    @cat = Cat.new
    render :new
  end
end
