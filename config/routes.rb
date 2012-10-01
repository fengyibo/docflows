# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

resources :docflows, :except => [:show] do
  collection do
    get 'in_work'
    get 'unread'
    get 'actual'
    get 'canceled'
    get 'created_by_me'
    get 'approved_by_me'
    get 'waiting_for_my_approvial'
    get 'sent_to_approvial'
    get 'under_control'
    get 'plugin_disabled'
  end
end

resources :docflow_categories, :except => [:show]

resources :docflow_types, :except => [:show]

resources :docflow_versions, :except => [:index] do
  member do
    get    'to_approvial'
    get    'postpone'
    get    'cancel'
    get    'accept'
    post   'approve'

    get    'checklist'
    post   'checklist', :action => 'add_checklists'
    delete 'remove_checklist/:cid', :action => 'remove_checklist'
    get    'copy_checklist/:vid', :action => 'copy_checklist'

    get    'show_file/:fid', :action => 'show_file'
    delete 'remove_file/:fid', :action => 'remove_file'
  end
end