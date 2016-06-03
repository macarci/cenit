Cenit::Application.routes.draw do

  devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks', sessions: 'sessions' } do
    get 'sign_out', to: 'users/sessions#destroy', as: :destroy_user_session
  end
  
  root to: 'rails_admin/main#dashboard'

  get 'explore/:api', to: 'api#explore', as: :explore_api
  post 'write/:api', to: 'api#write', as: :write_api

  match 'oauth/authorize', to: 'oauth#index', via: [:get, :post]
  get 'oauth/callback', to: 'oauth#callback'
  get 'schema', to: 'schema#index'
  get 'captcha', to: 'captcha#index'
  get 'captcha/:token', to: 'captcha#index'
  get '/file/:model/:field/:id/*file(.:format)', to: 'file#index'

  namespace :api do
    namespace :v1 do
      post '/auth/ping', to: 'api#auth'
      get  '/public/:model', to: 'api#index', ns: 'setup'
      get  '/public/:model/:id(.:format)', to: 'api#show', ns: 'setup', defaults: { format: 'json' }, constraints: {format: /(json)/}
      post '/setup/account', to: 'api#new_account'
      post '/:ns/push', to: 'api#push'
      post '/:ns/:model', to: 'api#new'
      get '/:ns/:model', to: 'api#index', defaults: { format: 'json' }
      get '/:ns/:model/:id', to: 'api#show', defaults: { format: 'json' }
      get '/:ns/:model/:id/:view', to: 'api#content', defaults: { format: 'json' }
      delete '/:ns/:model/:id', to: 'api#destroy'
      post '/:ns/:model/:id/pull', to: 'api#pull'
      post '/:ns/:model/:id/run', to: 'api#run'
      match '/auth', to: 'api#auth', via: [:head]
      match '/*path', to: 'api#cors_check', via: [:options]
    end

    namespace :v2 do
      post '/auth/ping', to: 'api#auth'
      get  '/public/:model', to: 'api#index', ns: 'setup'
      get  '/public/:model/:id(.:format)', to: 'api#show', ns: 'setup', defaults: { format: 'json' }, constraints: {format: /(json)/}
      post '/setup/account', to: 'api#new_account'
      post '/:ns/push', to: 'api#push'
      post '/:ns/:model', to: 'api#new'
      get '/:ns/:model', to: 'api#index', defaults: { format: 'json' }
      get '/:ns/:model/:id', to: 'api#show', defaults: { format: 'json' }
      get '/:ns/:model/:id/:view', to: 'api#content', defaults: { format: 'json' }
      delete '/:ns/:model/:id', to: 'api#destroy'
      post '/:ns/:model/:id/pull', to: 'api#pull'
      post '/:ns/:model/:id/run', to: 'api#run'
      match '/auth', to: 'api#auth', via: [:head]
      match '/*path', to: 'api#cors_check', via: [:options]
    end

  end

  match 'app/:ns/:app_slug' => 'app#index', via: [:all]
  match 'app/:ns/:app_slug/*path' => 'app#index', via: [:all]

  mount RailsAdmin::Engine => '/', as: 'rails_admin'

  get '/:model_name/*id', to: 'rails_admin/main#show'
end
