class Admin::HomeController < ApplicationController
  before_action :authenticate_user!
  before_action :check_admin_role

  def index
    render 'index'
  end

  private

  def check_admin_role
    unless current_user&.admin?
      redirect_to user_home_index_path, alert: 'Access Denied. You must be an admin to perform this action.'
    end
  end
end
