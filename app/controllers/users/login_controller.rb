class Users::LoginController < Devise::SessionsController
  before_filter :before_login, :only => :create
  after_filter :after_login, :only => :create

  def before_login
    session[:current_user_id] = nil
  end

  def after_login
    session[:current_user_id] = User.where(email: params['user']['email']).first.id
  end

end