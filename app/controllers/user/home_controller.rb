class User::HomeController < ApplicationController
  before_action :authenticate_user!

  def index
    @locations = []

    render 'index'
  end
end
