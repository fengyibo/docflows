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
        sql = ActiveRecord::Base.connection()
        qu = "SELECT v.* FROM #{DocflowVersion.table_name} v
              INNER JOIN
                  (SELECT dc.docflow_version_id FROM users u
                       INNER JOIN #{DocflowChecklist.table_name} dc ON
                         ((dc.user_id IS NOT NULL AND u.id = dc.user_id) OR
                          (dc.all_users='y' AND dc.user_department_id IS NULL AND dc.user_title_id IS NULL) OR
                          (dc.user_department_id IS NOT NULL AND dc.user_title_id IS NOT NULL AND dc.user_title_id=u.user_title_id AND dc.user_department_id=u.user_department_id AND dc.all_users IS NULL) OR
                          (dc.user_department_id IS NOT NULL AND dc.user_department_id=u.user_department_id AND dc.user_title_id IS NULL))
                    WHERE u.id=#{User.current.id}
                    GROUP BY dc.docflow_version_id) vids
              ON vids.docflow_version_id=v.id
              LEFT JOIN #{DocflowFamiliarization.table_name} df ON df.docflow_version_id=v.id AND df.user_id=#{User.current.id}
              WHERE v.docflow_status_id=3 AND df.done_date IS NULL"

        qu2 = "SELECT * FROM docflow_versions WHERE approver_id=#{User.current.id} AND docflow_status_id=2"
        res_uread = sql.execute(qu)
        res_waiting = sql.execute(qu2)
        ("<span>"+l(:label_docflow)+" ("+res_uread.size.to_s+"/"+res_waiting.size.to_s+")"+"</span>").html_safe
      end

    end

  end
end
