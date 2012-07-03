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
    end
  end
  
  match '/pages/graphs/:datatype/:group' => 'pages#graphs', :as => 'graphs_pages', :via => :get
  match '/pages/graphs/:datatype' => 'pages#graphs', :as => 'graphs_pages', :via => :get
  match '/pages/group/:id' => 'pages#group', :as => 'group_pages', :via => :get
  
  resources :groups, :only => [:index, :show] do

  end
  
  
end
