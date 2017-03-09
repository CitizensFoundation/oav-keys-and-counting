Rails.application.routes.draw do
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'
  #root 'votes#check_authentication'
  #root :to => redirect('/build/bundled/index.html')
  get "counting/counting_info"
  put "counting/start_count"
  get "counting/counting_progress"
  get "keys/boot"
  post "keys/create_public_private_key_pair"
end
