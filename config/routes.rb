Rails.application.routes.draw do
  mount Judge::Engine => '/judge'

  get 'home/index'
  root 'home#index'

  get 'password_resets/' => 'password_resets#index'
  get 'password_resets/new'
  get 'password_resets/edit'

  get 'artists/signup' => 'artists#signup'
  post 'artists/signup' => 'artists#create'

  get 'voters/signup' => 'voters#signup'
  post 'voters/signup' => 'voters#create'

  get 'admins/' => 'admins#index'
  post 'admins/index' => 'admins#index'
  get 'admins/signup' => 'admins#signup'
  post 'admins/signup' => 'admins#create'
  get 'admins/artists' => 'admins#artists'
  get 'admins/artist_info' => 'admins#artist_info'
  get 'admins/voters' => 'admins#voters'
  get 'admins/voter_info' => 'admins#voter_info'
  get 'admins/submissions' => 'admins#submissions'

  post 'artists/login' => 'sessions#create_artist'
  post 'voters/login' => 'sessions#create_voter'
  get 'voters/login' => 'sessions#voter_login'
  post 'admins/login' => 'sessions#create_admin'

  get 'artists/logout' => 'sessions#delete_artist'
  get 'voters/logout' => 'sessions#delete_voter'
  get 'admins/logout' => 'sessions#delete_admin'

  get 'account_activations/unactivated' => 'account_activations#unactivated'
  #get 'account_activations/resend_activation' => 'account_activations#resend_activation'

  post 'proposals/delete' => 'proposals#delete'

  post 'voters/vote' => 'voters#vote'

  post 'admins/assign' => 'admins#assign'
  post 'admins/clear_assignments' => 'admins#clear_assignments'
  get 'admins/reveal' => 'admins#reveal'
  post 'admins/verify' => 'admins#verify'
  post 'admins/send_fund_emails' => 'admins#send_fund_emails'
  post 'admins/send_question_emails' => 'admins#send_question_emails'


  resources :artists, :admins, :grant_submissions
  resources :grants, except: [:show]

  resources :grant_submissions do
    get 'discuss'
    post 'generate_contract'
  end

  resources :voters, only: [:create, :update, :index]
  resources :account_activations, only: [:edit]
  resources :password_resets, only: [:new, :create, :edit, :update]
  resources :proposals

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
