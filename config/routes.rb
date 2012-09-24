# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

resources :docflows, :except => [:show]
get 'docflows/unread', :to => "docflows#unread"
get 'docflows/in_work', :to =>"docflows#in_work"
get 'docflows/created_by_me', :to =>"docflows#created_by_me"
get 'docflows/approved_by_me', :to =>"docflows#approved_by_me"
get 'docflows/waiting_for_my_approvial', :to =>"docflows#waiting_for_my_approvial"
get 'docflows/sent_to_approvial', :to =>"docflows#sent_to_approvial"
get 'docflows/under_control', :to =>"docflows#under_control"
get 'docflows/actual', :to =>"docflows#actual"
get 'docflows/canceled', :to =>"docflows#canceled"
get 'docflows/plugin_disabled', :to =>"docflows#plugin_disabled"

resources :docflow_categories, :except => [:show] #:only => [:index,:edit,:create]

resources :docflow_versions, :except => [:index] # do
#   member do
#     get    'to_approvial'
#     get    'postpone'
#     get    'cancel'
#     get    'accept'
#     post   'approve'

#     get    'checklist'
#     post   'checklist', :to => 'add_checklists'
#     delete 'remove_checklist/:cid'

#     get    'show_file/:fid'
#     delete 'remove_file/:fid'
#   end
# end

get 'docflow_versions/:id/to_approvial', :to => "docflow_versions#to_approvial"
get 'docflow_versions/:id/postpone', :to => "docflow_versions#postpone"
get 'docflow_versions/:id/cancel', :to => "docflow_versions#cancel"
get 'docflow_versions/:id/accept', :to => "docflow_versions#accept"
post 'docflow_versions/:id/approve', :to => "docflow_versions#approve"

get 'docflow_versions/:id/checklist', :to => "docflow_versions#checklist"
post 'docflow_versions/:id/checklist', :to => "docflow_versions#add_checklists"
delete 'docflow_versions/:id/remove_checklist/:cid', :to => "docflow_versions#remove_checklist"

get 'docflow_versions/:id/show_file/:fid', :to => "docflow_versions#show_file"
delete 'docflow_versions/:id/remove_file/:fid', :to => "docflow_versions#remove_file"

