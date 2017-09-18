Rails.application.routes.draw do
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'
  #root 'votes#check_authentication'
  #root :to => redirect('/build/bundled/index.html')
  get "counting/counting_info"
  post "counting/start_counting"
  get "counting/counting_progress"
  get "counting/download_results_file"
  get "counting/download_results_zip"
  delete "counting/clear_all_votes"
  get "keys/boot"
  delete "keys/backup_and_reset"
  post "keys/create_public_private_key_pair"
  post "keys/restore_sql"
  get "keys/download_public_key_backup"
  get "keys/download_private_key_backup"
  get "keys/download_voting_database"
  post "keys/test_key_pair"
end
