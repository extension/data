Positronic::Application.routes.draw do
  root :to => 'home#index'
  resources :pages, :only => [:index, :show] do
    member do
      get :traffic_chart
    end
    collection do
      get :panda_impact_summary
      get :list
      post :setdate
      get :comparison_test
      get :graphs
    end
  end

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

    resources :pages, :only => [:index] do
      collection do
        get :graphs
      end
    end
  end

  # authentication
  match '/logout', to:'auth#end', :as => 'logout'
  match '/auth/:provider/callback', to: 'auth#success'

  # home routes
  match '/search', to:'home#search', :as => 'search'
  
  # catch all
  match '/:controller(/:action(/:id))'

end
