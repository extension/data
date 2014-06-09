Positronic::Application.routes.draw do
  root :to => 'home#index'
  resources :pages, :only => [:index, :show] do
    member do
      get :traffic_chart
    end
    collection do
      get :panda_impact_summary
      get :totals
      get :aggregate
      post :setdate
      get :comparison_test
      get :graphs
      get :details
      get :overview
      get :publishedcontent
    end
  end

  resources :groups, :only => [:index, :show]

  # data routes
  scope "data" do
    match "/groups", to: "data#groups", :as => 'data_groups'
  end

  resources :contributors, :only => [:show] do
    member do
      get :contributions
      get :metacontributions
    end
  end

  resources :nodes, :only => [:index, :show] do
    collection do
      get :graphs
      get :details
      get :list
    end
  end


  resources :groups, :only => [:index, :show] do
    member do
      get :pagelist
      get :pages
      get :pagetags
      get :nodes
      get :node_graphs
      get :node_activity
    end
  end


  # aae notice
  match '/aae', to: 'home#aae', :as => 'aae_notice'

  # authentication
  match '/logout', to:'auth#end', :as => 'logout'
  match '/auth/:provider/callback', to: 'auth#success'

  # home routes
  match '/search', to:'home#search', :as => 'search'

  # experiments named routes
  match '/experiments', to: 'experiments#index', :as => 'experiments'

  # catch all
  match '/:controller(/:action(/:id))'

end
