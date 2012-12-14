# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

# resources :explanations, :except => [:index]

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
    match  'to_approvial', :via => [:get, :post]
    match  'postpone', :via => [:get, :post]
    match  'cancel', :via => [:get, :post]
    match  'approve', :via => [:get, :post]
    get    'accept'


    get    'checklist'
    get    'autocomplete_for_user'
    post   'checklist', :action => 'add_checklists' 
    post   'edit_checklists/:department_id', :action => 'edit_checklists', :as => "edit_checklists"
    delete 'remove_checklist/:cid', :action => 'remove_checklist'
    delete 'remove_checklist_by_department/:department_id', :action => 'remove_checklist_by_department', :as => 'remove_checklist_by_department'
    get    'copy_checklist/:vid', :action => 'copy_checklist'

    get    'show_file/:fid', :action => 'show_file'
    delete 'remove_file/:fid', :action => 'remove_file'

    post   'add_comment', :action => 'add_comment'
    get    'show_comments', :action => 'show_comments'
    post   'update_comment/:cid', :action => 'update_comment'
    delete 'remove_comment/:cid', :action => 'remove_comment'
  end
end