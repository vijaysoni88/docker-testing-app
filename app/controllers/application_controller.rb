class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :redirect_admin_user, if: -> { user_signed_in? && request.fullpath == '/' }

  def after_sign_in_path_for(resource)
    if resource.admin?
      authenticated_admin_root_path
    else
      authenticated_user_root_path
    end
  end

  def after_sign_up_path_for(resource)
    after_sign_in_path_for(resource)
  end

  private

  def redirect_admin_user
    if current_user.admin?
      redirect_to admin_home_index_path
    else
      redirect_to user_home_index_path
    end
  end
end
