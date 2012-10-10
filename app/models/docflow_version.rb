class DocflowVersion < ActiveRecord::Base
  unloadable

  # Setting.plugin_docflows['cancel_allowed_to'].to_i

  belongs_to :docflow
  belongs_to :author, :class_name => "User", :foreign_key => :author_id
  belongs_to :approver, :class_name => "User", :foreign_key => :approver_id
  belongs_to :status, :class_name => "DocflowStatus", :foreign_key => :docflow_status_id

  has_many :checklists, :dependent => :destroy, :class_name => "DocflowChecklist"

  has_many :familarizations, :class_name => "DocflowFamiliarization"

  has_many :files, :class_name => "DocflowFile"
  before_destroy :drop_files
  before_save :validate_fields, :validate_conditions, :validate_permissions

  def validate_permissions
    errors.add(:base, l(:label_docflow_permissions_cant_save_document)) unless User.current.edit_docflows? || User.current.edit_docflows_in_category?(docflow.docflow_category_id)
    errors.blank?
  end

  def validate_fields
    errors.add(:author_id, l(:label_docflow_category_undefined)) if author_id.nil? || User.find(author_id).nil?
    #errors.add(:approver_id, "Approver should be defined!") if approver_id.nil? || User.find(approver_id).nil?
    errors.add(:docflow_status_id, l(:label_docflow_type_undefined)) if docflow_status_id.nil? || DocflowStatus.find(docflow_status_id).nil?
    errors.blank?
  end

  def validate_conditions
    df = Docflow.find(self.docflow_id)    

    if self.new_record?
      errors.add(:base, l(:label_docflow_actual_date_should_be_new_than_previous)) if !self.actual_date.nil? && df.versions.exists?(['actual_date >= ?', "#{self.actual_date}"])
      errors.add(:base, l(:label_docflow_only_new_possible_on_create)) unless self.docflow_status_id == 1      
      errors.add(:base, l(:label_docflow_cant_create_new_while_previous)) unless df.last_version.nil? || df.last_version.status.id == 3 || df.last_version.status.id == 4
    else
      errors.add(:base, l(:label_docflow_actual_date_should_be_new_than_previous)) if !self.actual_date.nil? && df.versions.where("id<>?",self.id).exists?(['actual_date >= ?', "#{self.actual_date}"])
      prev_state = DocflowVersion.find(self.id)
      errors.add(:base, l(:label_docflow_cant_edit_unless_last)) if self.id != self.docflow.last_version.id
      if docflow_status_id == 2
        vailidate_files_and_users
        errors.add(:base, l(:label_docflow_only_new_can_be_sent_to_approvial)) if !prev_state.nil? && !(prev_state.docflow_status_id == 1 || prev_state.docflow_status_id == 2)
      elsif docflow_status_id == 3
        vailidate_files_and_users
        errors.add(:base, l(:label_docflow_no_date_entry)) if self.actual_date.nil? || self.actual_date == ""
        errors.add(:base, l(:label_docflow_no_date_approvial)) if self.approve_date.nil? || self.approve_date == ""
        # validation removed due issue #3565
        # errors.add(:base, l(:label_docflow_cant_approve_if_not_on_approvial)) if !prev_state.nil? && prev_state.docflow_status_id != 2
      end
    end
    errors.blank?
  end

  def vailidate_files_and_users
      errors.add(:base, l(:label_docflow_no_files_attached)+(" <a href='#{self.id}/edit'>"+l(:label_docflow_edit_version)+"</a><br>").html_safe ) unless self.files.exists?(:filetype => "src_file") && self.files.exists?(:filetype => "pub_file")
      errors.add(:base, l(:label_docflow_no_users_attached)+(" <a href='#{self.id}/checklist'>"+l(:label_docflow_edit_check_list)+"</a><br>").html_safe ) unless self.checklists.any?
  end

  def visible_for_user?
    (user_in_checklist?(User.current.id) || [approver_id, docflow.responsible_id, author_id].include?(User.current.id) || 
    User.current.edit_docflows? || User.current.edit_docflows_in_category?(docflow.docflow_category_id) || 
    User.current.cancel_docflows? || User.current.approve_docflows?)
  end

  def editable_by_user?
    User.current.edit_docflows? || User.current.edit_docflows_in_category?(docflow.docflow_category_id)    
  end  

  def self.approved_by_me
    where("approver_id=? AND docflow_status_id=3", User.current.id)
  end

  def self.in_work
    where("author_id=? AND docflow_status_id=1", User.current.id)
  end

  def self.created_by_me
    where("author_id=?", User.current.id)
  end

  def self.sent_to_approvial
    where("author_id=? AND docflow_status_id=2", User.current.id)
  end

  def self.waiting_for_my_approvial
    where("approver_id=? AND docflow_status_id=2", User.current.id)
  end

  # todo: only actual and current versions should be selected
  # todo: profile of sql query in mysql
  def self.unread
    sql = "SELECT v.* FROM #{DocflowVersion.table_name} v
              INNER JOIN
                  (SELECT dc.docflow_version_id FROM #{User.table_name} u
                       INNER JOIN #{DocflowChecklist.table_name} dc ON
                         ((dc.user_id IS NOT NULL AND u.id = dc.user_id) OR
                          (dc.all_users='y' AND dc.user_department_id IS NULL AND dc.user_title_id IS NULL) OR
                          (dc.user_department_id IS NOT NULL AND dc.user_title_id IS NOT NULL AND dc.user_title_id=u.user_title_id AND dc.user_department_id=u.user_department_id AND dc.all_users IS NULL) OR
                          (dc.user_department_id IS NOT NULL AND dc.user_department_id=u.user_department_id AND dc.user_title_id IS NULL))
                    WHERE u.id=#{User.current.id}
                    GROUP BY dc.docflow_version_id) vids
              ON vids.docflow_version_id=v.id

              INNER JOIN (SELECT docflow_id, MAX(id) AS id FROM #{DocflowVersion.table_name} GROUP BY docflow_id) last_version 
              ON last_version.docflow_id=v.docflow_id              
              INNER JOIN (SELECT docflow_status_id, id FROM #{DocflowVersion.table_name}) last_status 
              ON last_status.id=last_version.id

          LEFT JOIN #{DocflowFamiliarization.table_name} df ON df.docflow_version_id=v.id AND df.user_id=#{User.current.id}
          WHERE v.docflow_status_id=3 AND df.done_date IS NULL AND last_status.docflow_status_id<4"
    find_by_sql(sql)
  end

  def self.unread_for_user
    sql = "SELECT v.* FROM #{DocflowVersion.table_name} v
              INNER JOIN
                  (SELECT * FROM 
                      (SELECT MAX(id) AS id, docflow_id FROM #{DocflowVersion.table_name} WHERE docflow_status_id=3 GROUP BY docflow_id
                        UNION
                       SELECT MAX(id) AS id, docflow_id FROM #{DocflowVersion.table_name} WHERE docflow_status_id=3 AND actual_date<NOW() GROUP BY docflow_id) two_or_one 
                  GROUP BY id,docflow_id) to_read
              ON to_read.id=v.id

              INNER JOIN
                  (SELECT dc.docflow_version_id FROM #{User.table_name} u
                       INNER JOIN #{DocflowChecklist.table_name} dc ON
                         ((dc.user_id IS NOT NULL AND u.id = dc.user_id) OR
                          (dc.all_users='y' AND dc.user_department_id IS NULL AND dc.user_title_id IS NULL) OR
                          (dc.user_department_id IS NOT NULL AND dc.user_title_id IS NOT NULL AND dc.user_title_id=u.user_title_id AND dc.user_department_id=u.user_department_id AND dc.all_users IS NULL) OR
                          (dc.user_department_id IS NOT NULL AND dc.user_department_id=u.user_department_id AND dc.user_title_id IS NULL))
                    WHERE u.id=#{User.current.id}
                    GROUP BY dc.docflow_version_id) with_checklist
              ON with_checklist.docflow_version_id=v.id

              INNER JOIN (SELECT docflow_id, MAX(id) AS id FROM #{DocflowVersion.table_name} GROUP BY docflow_id) last_version 
              ON last_version.docflow_id=v.docflow_id              
              INNER JOIN (SELECT docflow_status_id, id FROM #{DocflowVersion.table_name}) last_status 
              ON last_status.id=last_version.id

              LEFT JOIN #{DocflowFamiliarization.table_name} df ON df.docflow_version_id=v.id AND df.user_id=#{User.current.id}
           WHERE v.docflow_status_id=3 AND df.done_date IS NULL AND last_status.docflow_status_id<4"

    find_by_sql(sql)
  end

  # 
  def self.unread_actual
    sql = "SELECT v.* FROM #{DocflowVersion.table_name} v
              INNER JOIN
                  (SELECT dc.docflow_version_id FROM #{User.table_name} u
                       INNER JOIN #{DocflowChecklist.table_name} dc ON
                         ((dc.user_id IS NOT NULL AND u.id = dc.user_id) OR
                          (dc.all_users='y' AND dc.user_department_id IS NULL AND dc.user_title_id IS NULL) OR
                          (dc.user_department_id IS NOT NULL AND dc.user_title_id IS NOT NULL AND dc.user_title_id=u.user_title_id AND dc.user_department_id=u.user_department_id AND dc.all_users IS NULL) OR
                          (dc.user_department_id IS NOT NULL AND dc.user_department_id=u.user_department_id AND dc.user_title_id IS NULL))
                    WHERE u.id=#{User.current.id}
                    GROUP BY dc.docflow_version_id) vids
              ON vids.docflow_version_id=v.id    
              LEFT JOIN #{DocflowFamiliarization.table_name} df ON df.docflow_version_id=v.id AND df.user_id=#{User.current.id}

              INNER JOIN 
                (SELECT dv.docflow_id, MAX(dc.docflow_version_id) AS id FROM #{User.table_name} u
                    INNER JOIN #{DocflowChecklist.table_name} dc ON
                     ((dc.user_id IS NOT NULL AND u.id = dc.user_id) OR
                      (dc.all_users='y' AND dc.user_department_id IS NULL AND dc.user_title_id IS NULL) OR
                      (dc.user_department_id IS NOT NULL AND dc.user_title_id IS NOT NULL AND dc.user_title_id=u.user_title_id AND dc.user_department_id=u.user_department_id AND dc.all_users IS NULL) OR
                      (dc.user_department_id IS NOT NULL AND dc.user_department_id=u.user_department_id AND dc.user_title_id IS NULL))
                    INNER JOIN #{DocflowVersion.table_name} dv ON dv.id=dc.docflow_version_id AND dv.docflow_status_id>2
                  WHERE u.id=#{User.current.id}
                  GROUP BY dv.docflow_id) last_approved_checklist_version 
              ON last_approved_checklist_version.docflow_id=v.docflow_id

              INNER JOIN (SELECT docflow_id, MAX(id) AS id FROM #{DocflowVersion.table_name} GROUP BY docflow_id) last_version 
              ON last_version.docflow_id=v.docflow_id
              INNER JOIN (SELECT docflow_status_id, MAX(id) AS id FROM #{DocflowVersion.table_name} GROUP BY docflow_id) last_status 
              ON last_status.id=last_version.id

              INNER JOIN (SELECT docflow_id, MAX(id) AS id FROM #{DocflowVersion.table_name} WHERE docflow_status_id=3 AND actual_date <= NOW() GROUP BY docflow_id) current_version 
              ON current_version.docflow_id=v.docflow_id 
              
            WHERE v.docflow_status_id=3 AND last_status.docflow_status_id<4 AND (last_approved_checklist_version.id=v.id OR current_version.id=v.id) AND df.done_date IS NULL"
    find_by_sql(sql)
  end

  # selects only last accepted by user version if document was not canceled
  def self.actual
    sql = "SELECT v.* FROM #{DocflowVersion.table_name} v
              INNER JOIN
                (SELECT ver.docflow_id, MAX(ver.id) AS last_fam_id FROM #{DocflowVersion.table_name} ver 
                  INNER JOIN #{DocflowFamiliarization.table_name} fam ON fam.docflow_version_id=ver.id AND fam.user_id=#{User.current.id}
                 GROUP BY ver.docflow_id) ver_last ON ver_last.last_fam_id=v.id
              INNER JOIN (SELECT docflow_id, MAX(docflow_status_id) as stat FROM #{DocflowVersion.table_name} GROUP BY docflow_id) last_stat ON last_stat.docflow_id=v.docflow_id
            WHERE v.docflow_status_id=3 AND last_stat.stat<4"
    find_by_sql(sql)
  end

  # selects only last accepted version if document was not canceled and no any new approved unaccepted version
  def self.actual_for_user
    sql = "SELECT v.* FROM #{DocflowVersion.table_name} v
              INNER JOIN
                (SELECT docflow_id, MAX(id) AS id FROM #{DocflowVersion.table_name} WHERE docflow_status_id=3 AND actual_date<NOW() GROUP BY docflow_id) last_actual 
              ON last_actual.id=v.id
                  INNER JOIN #{DocflowFamiliarization.table_name} fam 
                  ON fam.docflow_version_id=last_actual.id AND fam.user_id=#{User.current.id}              
              INNER JOIN (SELECT docflow_id, MAX(docflow_status_id) AS stat FROM #{DocflowVersion.table_name} GROUP BY docflow_id) last_stat 
              ON last_stat.docflow_id=v.docflow_id
            WHERE v.docflow_status_id=3 AND last_stat.stat<4"
    find_by_sql(sql)
  end  

  # selects only last accepted version where document was canceled (last version canceled)
  def self.canceled
    sql = "SELECT v.* FROM #{DocflowVersion.table_name} v
              INNER JOIN
                (SELECT ver.docflow_id, MAX(ver.id) AS last_fam_id FROM #{DocflowVersion.table_name} ver 
                  INNER JOIN #{DocflowFamiliarization.table_name} fam ON fam.docflow_version_id=ver.id AND fam.user_id=#{User.current.id}
                 GROUP BY ver.docflow_id) ver_last ON ver_last.last_fam_id=v.id
              INNER JOIN (SELECT docflow_id, MAX(docflow_status_id) AS stat FROM #{DocflowVersion.table_name} GROUP BY docflow_id) last_stat ON last_stat.docflow_id=v.docflow_id
            WHERE v.docflow_status_id>2 AND last_stat.stat=4"
    find_by_sql(sql)
  end

  # if document canceled or user not in last fam-list
  # Выбрать последнюю (одну) версию с которой ознакомился
  # где самая последняя версия отменена
  # или есть еще более новая версия со статусом > 2 после версии с которой ознакомился, где пользователь не в листе на ознакомление
  def self.canceled_for_user
    sql = "SELECT v.* FROM #{DocflowVersion.table_name} v
              INNER JOIN
                (SELECT ver.docflow_id, MAX(ver.id) AS id FROM #{DocflowVersion.table_name} ver 
                  INNER JOIN #{DocflowFamiliarization.table_name} fam ON fam.docflow_version_id=ver.id AND fam.user_id=#{User.current.id}
                 GROUP BY ver.docflow_id) last_fam 
              ON last_fam.id=v.id

              INNER JOIN 
                (SELECT dv.docflow_id, MAX(dc.docflow_version_id) AS id FROM #{User.table_name} u
                    INNER JOIN #{DocflowChecklist.table_name} dc ON
                     ((dc.user_id IS NOT NULL AND u.id = dc.user_id) OR
                      (dc.all_users='y' AND dc.user_department_id IS NULL AND dc.user_title_id IS NULL) OR
                      (dc.user_department_id IS NOT NULL AND dc.user_title_id IS NOT NULL AND dc.user_title_id=u.user_title_id AND dc.user_department_id=u.user_department_id AND dc.all_users IS NULL) OR
                      (dc.user_department_id IS NOT NULL AND dc.user_department_id=u.user_department_id AND dc.user_title_id IS NULL))
                    INNER JOIN #{DocflowVersion.table_name} dv ON dv.id=dc.docflow_version_id AND dv.docflow_status_id>2
                  WHERE u.id=#{User.current.id}
                  GROUP BY dv.docflow_id) last_checklist_version 
              ON last_checklist_version.docflow_id=v.docflow_id

              INNER JOIN (SELECT docflow_id, MAX(id) AS id FROM #{DocflowVersion.table_name} GROUP BY docflow_id) last_version 
              ON last_version.docflow_id=v.docflow_id

              INNER JOIN (SELECT docflow_status_id, id FROM #{DocflowVersion.table_name}) last_status 
              ON last_status.id=last_version.id
              
            WHERE last_status.docflow_status_id=4 OR last_checklist_version.id<last_version.id"
    find_by_sql(sql)
  end  

 

  # approved versions with familiarization for user
  def self.for_familiarization
    sql = "SELECT v.* FROM #{DocflowVersion.table_name} v
          INNER JOIN
              (SELECT dc.docflow_version_id FROM #{User.table_name} u
                   INNER JOIN #{DocflowChecklist.table_name} dc ON
                     ((dc.user_id IS NOT NULL AND u.id = dc.user_id) OR
                      (dc.all_users='y' AND dc.user_department_id IS NULL AND dc.user_title_id IS NULL) OR
                      (dc.user_department_id IS NOT NULL AND dc.user_title_id IS NOT NULL AND dc.user_title_id=u.user_title_id AND dc.user_department_id=u.user_department_id AND dc.all_users IS NULL) OR
                      (dc.user_department_id IS NOT NULL AND dc.user_department_id=u.user_department_id AND dc.user_title_id IS NULL))
                WHERE u.id=#{User.current.id}
                GROUP BY dc.docflow_version_id) vids
          ON vids.docflow_version_id=v.id
          INNER JOIN #{DocflowFamiliarization.table_name} df ON df.docflow_version_id=v.id AND df.user_id=#{User.current.id}
          WHERE v.docflow_status_id=3"
    find_by_sql(sql)
  end 

  def familiarization_list
    sql = "SELECT #{User.table_name}.* FROM #{User.table_name}
              INNER JOIN
              (SELECT u.id FROM #{User.table_name} u
               INNER JOIN #{DocflowChecklist.table_name} dc ON dc.docflow_version_id=#{self.id} AND
                 ((dc.user_id IS NOT NULL AND u.id = dc.user_id) OR
                  (dc.all_users='y' AND dc.user_department_id IS NULL AND dc.user_title_id IS NULL) OR
                  (dc.user_department_id IS NOT NULL AND dc.user_title_id IS NOT NULL AND
                    dc.user_title_id=u.user_title_id AND dc.user_department_id=u.user_department_id) OR
                  (dc.user_department_id IS NOT NULL AND dc.user_department_id=u.user_department_id AND dc.user_title_id IS NULL))
              GROUP BY u.id) uids ON uids.id=#{User.table_name}.id
           WHERE #{User.table_name}.type='User'"
    User.find_by_sql(sql)
  end

  def user_in_checklist?(uid)
    sql = "SELECT #{User.table_name}.* FROM #{User.table_name}
              INNER JOIN
              (SELECT u.id FROM #{User.table_name} u
               INNER JOIN #{DocflowChecklist.table_name} dc ON dc.docflow_version_id=#{self.id} AND
                 ((dc.user_id IS NOT NULL AND u.id = dc.user_id) OR
                  (dc.all_users='y' AND dc.user_department_id IS NULL AND dc.user_title_id IS NULL) OR
                  (dc.user_department_id IS NOT NULL AND dc.user_title_id IS NOT NULL AND
                    dc.user_title_id=u.user_title_id AND dc.user_department_id=u.user_department_id) OR
                  (dc.user_department_id IS NOT NULL AND dc.user_department_id=u.user_department_id AND dc.user_title_id IS NULL))
              GROUP BY u.id) uids ON uids.id=#{User.table_name}.id
           WHERE #{User.table_name}.type='User' AND #{User.table_name}.id=#{uid}"
    !User.find_by_sql(sql).first.nil?
    # && User.find_by_sql(sql).first.id == uid
  end

  def last?
    id == docflow.last_version.id
  end

  def prev_version
    docflow.versions.where("id<?",self.id).order(:id).last
  end  

  # attr_accessor :failed_files
  attr_accessor :errors_msgs
  attr_accessor :processed_checklists

  # Prepearing NEW files to save.
  # Filling file info via DocflowFile.file= method, then creates new file on disk

  def save_files(new_files)
    failed_files,self.errors_msgs = [],[]
    docfile = nil
    num_files = 0
    new_files = new_files.values if new_files.is_a?(Hash)
    files_left = Setting.plugin_docflows['max_files'].to_i - self.files.count
    if new_files.is_a?(Array)
      new_files.each do |new_file|
        if new_file['file'].respond_to?(:original_filename)
          num_files += 1
          err = false

          docfile = DocflowFile.new( :file => new_file['file'],
                                     :docflow_version_id => self.id,
                                     :description => new_file['description'],
                                     :filetype => new_file['filetype'] )

          if docfile.filetype == "pub_file" && !docfile.pdf?
            self.errors_msgs << l(:label_docflow_file_not_pdf)
            err = true
          elsif docfile.filetype == "src_file" && !docfile.docx?
            self.errors_msgs << l(:label_docflow_file_not_docx)
            err = true
          end

          unless docfile.allowed_type?
            self.errors_msgs << l(:label_docflow_file_type_not_allowed)
            err = true
          end

          if num_files > files_left
            self.errors_msgs << l( :label_docflow_file_more_than_allowed_files, 
                                   :max_files => Setting.plugin_docflows['max_files'].to_s, 
                                   :fname => docfile.filename )
            err = true
          end

          docfile.save unless err

          if docfile.new_record?
            failed_files << new_file
          end
        end
      end
      self.errors_msgs << l(:label_docflow_files_not_saved, :num_files => failed_files.size.to_s) if failed_files.size > 0
    end
  end

  def save_checklists(is_all, users, titles, department)
    self.processed_checklists,self.errors_msgs = [],[]
    rec = nil
    deleted = ""

    users = users.values if users.is_a?(Hash)
    titles = titles.values if titles.is_a?(Hash)

    # Only one type of possible record variants will be added at one time
    # Case:  ALL | Users | Titel+Department | Title | Department
    if !is_all.nil? && is_all == 'y'
      rec = DocflowChecklist.create( :docflow_version_id => self.id,
                                     :all_users => 'y' )      

      self.processed_checklists << { :name => l(:label_docflows_all_users),
                                     :id => rec.id,
                                     :type => "all" } unless rec.new_record?

      self.errors_msgs << '&middot; '+l(:label_docflows_all_users) if rec.new_record?
    elsif users.is_a?(Array)
      users.each do |uid|
        rec = DocflowChecklist.create( :docflow_version_id => self.id,
                                       :user_id => uid )

        self.processed_checklists << { :name => rec.user.name,
                                       :id => rec.id,
                                       :type => "User" } unless rec.new_record?

        self.errors_msgs << '&middot; '+rec.user.name if rec.new_record?
      end
    elsif titles.is_a?(Array)
      titles.each do |tid|
        rec = DocflowChecklist.create( :docflow_version_id => self.id,
                                       :user_title_id => tid,
                                       :user_department_id => ((department.nil?) ? nil : department) )

        name = ( rec.department.nil? ? "" : (rec.department.name + ", ")) + rec.title.name
        self.processed_checklists << { :name => name,
                                       :id => rec.id,
                                       :type => "UserTitle" } unless rec.new_record?

        self.errors_msgs << '&middot; '+name if rec.new_record?
      end
    elsif !department.nil? && department != ""
      rec = DocflowChecklist.create( :docflow_version_id => self.id,
                                     :user_department_id => department )

      self.processed_checklists << { :name => rec.department.name,
                                     :id => rec.id,
                                     :type => "Department" } unless rec.new_record?

      self.errors_msgs << '&middot; '+rec.department.name if rec.new_record?
    end
    self.errors_msgs.unshift(l(:label_docflow_check_list_similar_records)) if self.errors_msgs.any?
  end

  def copy_checklist(from_version)
    # ordered by id due unsorted selection may cause of all_users will be selected 
    # before personal and next recods would not be saved
    unless self.new_record? || from_version.nil?
      from_version.checklists.order(:id).each do |rec|
        DocflowChecklist.create( :docflow_version_id => self.id,
                                 :user_id => rec.user_id,
                                 :user_title_id => rec.user_title_id,
                                 :user_department_id => rec.user_department_id,
                                 :all_users => rec.all_users )
      end
    end
  end

  # Purges all files from disk and clear table records
  # Collects number of fails during DocflowFile.destoy

  def drop_files
    failed_files = []
    files.each {|attached_file| failed_files << attached_file unless attached_file.destroy}
  end

end
