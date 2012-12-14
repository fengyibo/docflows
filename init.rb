Redmine::Plugin.register :docflows do
  name 'Document Workflows plugin'
  author 'Danil Kukhlevskiy'
  description 'This is a plugin for managing lifecycle of office documents'
  version '0.0.1'
  url 'http://redmine.prp.ru/docflows'
  author_url 'http://example.com/about'

  
  settings  :partial => 'settings/docflows_settings',
            :default => { "docflows_max_file_size" => "5196",
                          "docflows_max_files" => "7",
                          "docflows_enabled_extensions" => "docx,pdf,jpg,jpeg,gif,txt,doc,xls,xlsx,png",
                          "docflows_storage_path" => File.join(Rails.root, "files") }

  menu :top_menu, :docflow, { :controller => 'docflows', :action => 'index' }, :caption => Proc.new {User.current.df_top_menu_link}, :if => Proc.new { Setting.plugin_docflows['enable_plugin'] && User.current.logged? }

  project_module :docflows do
    permission :edit_docflows, :docflows => [:new, :create, :edit, :update, :destroy]
    permission :edit_versions, :docflow_versions => [:new, :update, :edit, :create, :checklist, :copy_checklist, :add_checklists, :edit_checklists, :remove_checklist, :remove_checklist_by_department, :to_approvial, :postpone, :destroy]
    permission :approve_versions, :docflow_versions => [:approve]
    permission :cancel_versions, :docflow_versions => [:cancel]
    permission :edit_categories, :docflow_categories => [:index, :new, :create, :update, :edit, :destroy]
    permission :edit_types, :docflow_types => [:index, :new, :create, :update, :edit, :destroy]
    permission :comment_versions, :docflow_versions => [:show_comments, :add_comment, :update_comment, :remove_comment]
  end

  # requires_redmine_plugin :global_roles, :version_or_higher => '0.0.0'
  # if Redmine::Plugin.registered_plugins.keys.include?(:global_roles)
end

Rails.application.config.to_prepare do
  User.send(:include, Docflows::UserPatch)
end