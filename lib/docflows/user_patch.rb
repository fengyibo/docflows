require_dependency 'project'
require_dependency 'principal'
require_dependency 'user'

module Docflows
  module UserPatch
    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do
        has_many :familiarizations, :class_name => 'DocflowFamiliarization', :foreign_key => 'user_id'
      end

    end

    module ClassMethods
    end

    module InstanceMethods
      def read_date(ver)
        rec = familiarizations.where('docflow_version_id=?', ver).first
        rec.done_date unless rec.nil?
      end

      def edit_docflows_categories?
        return true if self.admin?
        unless Setting.plugin_docflows['edit_categories_allowed_to'].nil?
          Group.find(Setting.plugin_docflows['edit_categories_allowed_to']).users.exists?(self.id)
        end
      end

      def edit_docflows?
        return true if self.admin?
        unless Setting.plugin_docflows['edit_documents_allowed_to'].nil?
          Group.find(Setting.plugin_docflows['edit_documents_allowed_to']).users.exists?(self.id)
        end
      end

      def edit_docflows_in_category?(category_id)
        return true if self.admin?
        category = DocflowCategory.find(category_id)
        unless category.nil?
          self.user_department_id == category.editor_department_id && self.user_title_id == category.editor_title_id
        end
      end      

      def edit_docflows_in_some_category?
        return true if self.admin?
        category = DocflowCategory.where("editor_department_id=? AND editor_title_id=?",self.user_department_id,self.user_title_id)
        return !category.first.nil?
      end      

      def approve_docflows?
        return true if self.admin?
        unless Setting.plugin_docflows['approve_allowed_to'].nil?
          Group.find(Setting.plugin_docflows['approve_allowed_to']).users.exists?(self.id)
        end
      end

      def cancel_docflows?
        return true if self.admin?
        unless Setting.plugin_docflows['cancel_allowed_to'].nil?
          Group.find(Setting.plugin_docflows['cancel_allowed_to']).users.exists?(self.id)
        end
      end

      def df_top_menu_link
        unread = DocflowVersion.unread_for_user.count
        waiting = DocflowVersion.waiting_for_my_approvial.count
        top_indicator = " ("+unread.to_s + ((waiting == 0) ? "" : ("/"+waiting.to_s)) + ")"
        ("<span>"+l(:label_docflow)+top_indicator+"</span>").html_safe
      end

    end

  end
end
