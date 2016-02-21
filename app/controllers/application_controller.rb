class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.

  protect_from_forgery with: :null_session,
                       if: Proc.new { |c| c.request.format =~ %r{application/json} }

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to main_app.root_path, :alert => exception.message
  end

  def doorkeeper_oauth_client
    @client ||= OAuth2::Client.new(DOORKEEPER_APP_ID, DOORKEEPER_APP_SECRET, :site => DOORKEEPER_APP_URL)
  end

  # expired?
  # refresh!
  def doorkeeper_access_token
    opts = {}
    if current_user
      opts[:refresh_token] = current_user.doorkeeper_refresh_token
      opts[:expires_at] = current_user.doorkeeper_expires_at
    end
    @token ||= OAuth2::AccessToken.new(doorkeeper_oauth_client, current_user.doorkeeper_access_token, opts) if current_user
  end

  around_filter :scope_current_account, :clean_thread_cache, :optimize_data_type_handling

  after_action :clean_thread_cache

  protected

  def do_optimize_data_type_handling
    Setup::DataTypeOptimizer.new_optimizer
  end

  private

  def optimize_data_type_handling
    do_optimize_data_type_handling
    yield
  end

  def clean_thread_cache
    [
      :optimizer,
      :flow_execution,
      :mongoff_models,
      :mongoff_abstract_models
    ].each { |sym| Thread.current[sym] = nil }
    yield if block_given?
  end

  def scope_current_account
    if current_user && current_user.account.nil?
      current_user.add_role(:admin) unless current_user.has_role?(:admin)
      current_user.account = Account.create_with_owner(owner: current_user)
      current_user.save(validate: false)
    end
    Account.current = current_user.account if signed_in?
    yield
  ensure
    if account = Account.current
      account.save
    end
    Account.current = nil
  end

  def after_sign_out_path_for(resource_or_scope)
    ENV['SING_OUT_URL'] || root_path
  end
end
