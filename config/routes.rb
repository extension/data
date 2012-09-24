Positronic::Application.routes.draw do
  root :to => 'home#index'
  resources :pages, :only => [:index, :show] do
    member do
      get :traffic_chart
    end
    collection do
      get :panda_impact_summary
      get :groups
      get :list
      post :setdate
      post :search
      get :comparison_test
    end
  end

  # pretty url matchers
  match '/pages/graphs/:datatype/:group', to: 'pages#graphs', :as => 'graphs_pages', :via => :get
  match '/pages/graphs/:datatype', to: 'pages#graphs', :as => 'graphs_pages', :via => :get
  match '/pages/datatype/:datatype', to:'pages#datatype', :as => 'datatype_pages', :via => :get

  resources :groups, :only => [:index, :show]

  # data routes
  scope "data" do
    match "/groups", to: "data#groups", :as => 'data_groups'
  end



  resources :contributors, :only => [:index, :show] do
    member do
      get :contributions
      get :metacontributions
    end
  end

  resources :nodes, :only => [:index, :show] do
    collection do
      get :graphs
    end
  end


  resources :groups, :only => [:index, :show] do
    member do
      get :pagelist
    end
  end

  # authentication
  match '/logout', to:'auth#end', :as => 'logout'
  match '/auth/:provider/callback', to: 'auth#success'

  # catch all
  match '/:controller(/:action(/:id))'

end
