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
  before_save :validate_fields, :validate_conditions

  validate :validate_permissions

  def validate_permissions
    errors.add(:base, l(:label_docflow_permissions_cant_save_document)) unless User.current.edit_docflows? || User.current.edit_docflows_in_category?(docflow.docflow_category_id)
    # errors.add(:base, l(:label_docflow_permissions_cant_save_document_in_category)) unless User.current.edit_docflows_in_category?(docflow.docflow_category_id)    
  end

  def validate_fields
    errors.add(:author_id, l(:label_docflow_category_undefined)) if author_id.nil? || User.find(author_id).nil?
    #errors.add(:approver_id, "Approver should be defined!") if approver_id.nil? || User.find(approver_id).nil?
    errors.add(:docflow_status_id, l(:label_docflow_type_undefined)) if docflow_status_id.nil? || DocflowStatus.find(docflow_status_id).nil?
    return false if errors.any?
  end

  def validate_conditions
    if self.new_record?
      errors.add(:base, l(:label_docflow_only_new_possible_on_create)) unless self.docflow_status_id == 1
      df = Docflow.find(self.docflow_id)
      errors.add(:base, l(:label_docflow_cant_create_new_while_previous)) unless df.last_version.nil? || df.last_version.status.id == 3 || df.last_version.status.id == 4
    else
      prev_state = DocflowVersion.find(self.id)
      errors.add(:base, l(:label_docflow_cant_edit_unless_last)) if self.id != self.docflow.last_version.id
      if docflow_status_id == 2
        vailidate_files_and_users
        errors.add(:base, l(:label_docflow_only_new_can_be_sent_to_approvial)) if !prev_state.nil? && !(prev_state.docflow_status_id == 1 || prev_state.docflow_status_id == 2)
      elsif docflow_status_id == 3
        vailidate_files_and_users
        errors.add(:base, l(:label_docflow_no_date_entry)) if self.actual_date.nil? || self.actual_date == ""
        errors.add(:base, l(:label_docflow_no_date_approvial)) if self.approve_date.nil? || self.approve_date == ""
        errors.add(:base, l(:label_docflow_cant_approve_if_not_on_approvial)) if !prev_state.nil? && prev_state.docflow_status_id != 2
      end
    end
    return false if errors.any?
  end

  def vailidate_files_and_users
      errors.add(:base, l(:label_docflow_no_files_attached)) unless self.files.any?
      errors.add(:base, l(:label_docflow_no_users_attached)) unless self.checklists.any?
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
    sql = "SELECT v.* FROM docflow_versions v
          INNER JOIN
              (SELECT dc.docflow_version_id FROM users u
                   INNER JOIN docflow_checklists dc ON
                     ((dc.user_id IS NOT NULL AND u.id = dc.user_id) OR
                      (dc.all_users='y' AND dc.user_department_id IS NULL AND dc.user_title_id IS NULL) OR
                      (dc.user_department_id IS NOT NULL AND dc.user_title_id IS NOT NULL AND dc.user_title_id=u.user_title_id AND dc.user_department_id=u.user_department_id AND dc.all_users IS NULL) OR
                      (dc.user_department_id IS NOT NULL AND dc.user_department_id=u.user_department_id AND dc.user_title_id IS NULL))
                WHERE u.id=#{User.current.id}
                GROUP BY dc.docflow_version_id) vids
          ON vids.docflow_version_id=v.id
          LEFT JOIN docflow_familiarizations df ON df.docflow_version_id=v.id AND df.user_id=#{User.current.id}
          WHERE v.docflow_status_id=3 AND df.done_date IS NULL"
    find_by_sql(sql)
  end

  # selects only last accepted version if document was not canceled
  def self.actual
    sql = "SELECT v.* FROM docflow_versions v
              INNER JOIN
                (SELECT ver.docflow_id, MAX(ver.id) AS last_fam_id FROM docflow_versions ver 
                  INNER JOIN docflow_familiarizations fam ON fam.docflow_version_id=ver.id AND fam.user_id=#{User.current.id}
                 GROUP BY ver.docflow_id) ver_last ON ver_last.last_fam_id=v.id
              INNER JOIN (SELECT docflow_id, MAX(docflow_status_id) as stat FROM docflow_versions GROUP BY docflow_id) last_stat ON last_stat.docflow_id=v.docflow_id
            WHERE v.docflow_status_id=3 AND last_stat.stat<4"
    find_by_sql(sql)
  end

  # selects only last accepted version if document was not canceled and no any new approved unaccepted version
  def self.actual_for_user
    sql = "SELECT v.* FROM docflow_versions v
              INNER JOIN
                (SELECT docflow_id, MAX(id) AS id FROM docflow_versions WHERE docflow_status_id=3 AND actual_date<NOW() GROUP BY docflow_id) last_actual 
              ON last_actual.id=v.id
                 INNER JOIN docflow_familiarizations fam ON fam.docflow_version_id=last_actual.id AND fam.user_id=#{User.current.id}
              
              INNER JOIN (SELECT docflow_id, MAX(docflow_status_id) as stat FROM docflow_versions GROUP BY docflow_id) last_stat 
              ON last_stat.docflow_id=v.docflow_id
            WHERE v.docflow_status_id=3 AND last_stat.stat<4"
    find_by_sql(sql)
  end  

  # actual versions with familiarization for user
  def self.for_familiarization
    sql = "SELECT v.* FROM docflow_versions v
          INNER JOIN
              (SELECT dc.docflow_version_id FROM users u
                   INNER JOIN docflow_checklists dc ON
                     ((dc.user_id IS NOT NULL AND u.id = dc.user_id) OR
                      (dc.all_users='y' AND dc.user_department_id IS NULL AND dc.user_title_id IS NULL) OR
                      (dc.user_department_id IS NOT NULL AND dc.user_title_id IS NOT NULL AND dc.user_title_id=u.user_title_id AND dc.user_department_id=u.user_department_id AND dc.all_users IS NULL) OR
                      (dc.user_department_id IS NOT NULL AND dc.user_department_id=u.user_department_id AND dc.user_title_id IS NULL))
                WHERE u.id=#{User.current.id}
                GROUP BY dc.docflow_version_id) vids
          ON vids.docflow_version_id=v.id
          INNER JOIN docflow_familiarizations df ON df.docflow_version_id=v.id AND df.user_id=#{User.current.id}
          WHERE v.docflow_status_id=3"
    find_by_sql(sql)
  end 

  # selects only last accepted version where document was canceled (last version canceled)
  def self.canceled
    sql = "SELECT v.* FROM docflow_versions v
              INNER JOIN
                (SELECT ver.docflow_id, MAX(ver.id) AS last_fam_id FROM docflow_versions ver 
                  INNER JOIN docflow_familiarizations fam ON fam.docflow_version_id=ver.id AND fam.user_id=#{User.current.id}
                 GROUP BY ver.docflow_id) ver_last ON ver_last.last_fam_id=v.id
              INNER JOIN (SELECT docflow_id, MAX(docflow_status_id) as stat FROM docflow_versions GROUP BY docflow_id) last_stat ON last_stat.docflow_id=v.docflow_id
            WHERE v.docflow_status_id>2 AND last_stat.stat=4"
    find_by_sql(sql)
  end

  # if document canceled or user not in last fam-list
  def self.canceled_for_user
    sql = "SELECT v.* FROM docflow_versions v
              INNER JOIN
                (SELECT ver.docflow_id, MAX(ver.id) AS last_fam_id FROM docflow_versions ver 
                  INNER JOIN docflow_familiarizations fam ON fam.docflow_version_id=ver.id AND fam.user_id=#{User.current.id}
                 GROUP BY ver.docflow_id) ver_last ON ver_last.last_fam_id=v.id
              INNER JOIN (SELECT docflow_id, MAX(docflow_status_id) as stat FROM docflow_versions GROUP BY docflow_id) last_stat ON last_stat.docflow_id=v.docflow_id
            WHERE v.docflow_status_id>2 AND last_stat.stat=4"
    find_by_sql(sql)
  end

  def familiarization_list
    sql = "SELECT users.* FROM users
              INNER JOIN
              (SELECT u.id FROM users u
               INNER JOIN docflow_checklists dc ON dc.docflow_version_id=#{self.id} AND
                 ((dc.user_id IS NOT NULL AND u.id = dc.user_id) OR
                  (dc.all_users='y' AND dc.user_department_id IS NULL AND dc.user_title_id IS NULL) OR
                  (dc.user_department_id IS NOT NULL AND dc.user_title_id IS NOT NULL AND
                    dc.user_title_id=u.user_title_id AND dc.user_department_id=u.user_department_id) OR
                  (dc.user_department_id IS NOT NULL AND dc.user_department_id=u.user_department_id AND dc.user_title_id IS NULL))
              GROUP BY u.id) uids ON uids.id=users.id
           WHERE users.type='User'"
    User.find_by_sql(sql)
  end

  def user_in_checklist?(uid)
    sql = "SELECT users.* FROM users
              INNER JOIN
              (SELECT u.id FROM users u
               INNER JOIN docflow_checklists dc ON dc.docflow_version_id=#{self.id} AND
                 ((dc.user_id IS NOT NULL AND u.id = dc.user_id) OR
                  (dc.all_users='y' AND dc.user_department_id IS NULL AND dc.user_title_id IS NULL) OR
                  (dc.user_department_id IS NOT NULL AND dc.user_title_id IS NOT NULL AND
                    dc.user_title_id=u.user_title_id AND dc.user_department_id=u.user_department_id) OR
                  (dc.user_department_id IS NOT NULL AND dc.user_department_id=u.user_department_id AND dc.user_title_id IS NULL))
              GROUP BY u.id) uids ON uids.id=users.id
           WHERE users.type='User' AND users.id=#{uid}"
    !User.find_by_sql(sql).first.nil? && User.find_by_sql(sql).first.id == uid
  end

  attr_accessor :saved_files
  attr_accessor :failed_files
  attr_accessor :errors_msgs

  attr_accessor :processed_checklists

  # Prepearing NEW files to save.
  # Filling file info via DocflowFile.file= method, then creates new file on disk

  def save_files(new_files)
    self.saved_files,self.failed_files,self.errors_msgs = [],[],[]
    docfile = nil
    num_files = 0
    new_files = new_files.values if new_files.is_a?(Hash)
    files_left = Setting.plugin_docflows['max_files'].to_i - self.files.count
    if new_files.is_a?(Array)
      new_files.each do |new_file|
        if new_file['file'].respond_to?(:original_filename)
          num_files += 1
          err = ""

          docfile = DocflowFile.new( :file => new_file['file'],
                                     :docflow_version_id => self.id,
                                     :description => new_file['description'],
                                     :filetype => new_file['filetype'] )

          err = ("<br>"+l(:label_docflow_file_not_pdf)).html_safe if docfile.filetype == "pub_file" && !docfile.pdf?
          err += ("<br>"+l(:label_docflow_file_not_docx)).html_safe if docfile.filetype == "src_file" && !docfile.docx?
          err += ("<br>"+l(:label_docflow_file_type_not_allowed)+docfile.filename).html_safe unless docfile.allowed_type?
          err += ("<br>"+l(:label_docflow_file_more_than_allowed_files, 
                           :max_files => Setting.plugin_docflows['max_files'].to_s, 
                           :fname => docfile.filename)).html_safe if num_files > files_left

          docfile.save if err == ""

          if docfile.new_record?
            self.failed_files << new_file
            self.errors_msgs << err
          else
            self.saved_files << new_file
          end
        end
      end
    end
  end

  # todo: check if record exists in checklists model before save
  def save_checklists(is_all, users, titles, department)
    self.processed_checklists = []
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
                                     :type => "all",
                                     :docflow_version_id => self.id,
                                     :err => ((rec.new_record?) ? "Exists" : "") }
    elsif users.is_a?(Array)
      users.each do |uid|
        rec = DocflowChecklist.create( :docflow_version_id => self.id,
                                       :user_id => uid ) #if uid.is_a?(Numeric)

        self.processed_checklists << { :name => rec.user.name,
                                       :id => rec.id,
                                       :type => "User",
                                       :docflow_version_id => self.id,
                                       :err => ((rec.new_record?) ? "Exists" : "") }
      end
    elsif titles.is_a?(Array)
      titles.each do |tid|
        rec = DocflowChecklist.create( :docflow_version_id => self.id,
                                       :user_title_id => tid,
                                       :user_department_id => ((department.nil?) ? nil : department) )

        self.processed_checklists << { :name => ( rec.department.nil? ? "" : (rec.department.name + ", ")) + rec.title.name,
                                       :id => rec.id,
                                       :type => "UserTitle",
                                       :docflow_version_id => self.id,
                                       :err => ((rec.new_record?) ? "Exists" : "") }
      end
    elsif !department.nil? && department != ""
      rec = DocflowChecklist.create( :docflow_version_id => self.id,
                                     :user_department_id => department )

      self.processed_checklists << { :name => rec.department.name,
                                     :id => rec.id,
                                     :type => "Department",
                                     :docflow_version_id => self.id,
                                     :err => ((rec.new_record?) ? "Exists" : "") }
    end
  end

  # Purges all files from disk and clear table records
  # Collects number of fails during DocflowFile.destoy

  def drop_files
    self.saved_files,self.failed_files = [],[]
    files.each {|attached_file| self.failed_files << attached_file unless attached_file.destroy}
  end

end