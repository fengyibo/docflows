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
    permission :new_docflows, :docflows => :new
    permission :new_versions, :docflow_versions => :new
  end

  # requires_redmine_plugin :global_roles, :version_or_higher => '0.0.0'
  # if Redmine::Plugin.registered_plugins.keys.include?(:global_roles)
end

Rails.application.config.to_prepare do
  User.send(:include, Docflows::UserPatch)
end