class DocflowChecklist < ActiveRecord::Base
  unloadable

  belongs_to :version, :class_name => "DocflowVersion", :foreign_key => :docflow_version_id

  belongs_to :user
  belongs_to :department, :class_name => "UserDepartment", :foreign_key => :user_department_id
  belongs_to :title, :class_name => "UserTitle", :foreign_key => :user_title_id
  belongs_to :group_set

  validate  :no_similar_record_exists?

  def no_similar_record_exists?
    errors.add(:user_id, l(:label_docflow_check_list_similar_records)) if same_record?
  end

  def extended_records?
    DocflowChecklist.where( "docflow_version_id=? AND
                             ( all_users='y' OR user_id=? OR
                               (user_department_id=? AND user_title_id IS NULL) OR
                               (user_department_id IS NULL AND user_title_id=?) )",
                            docflow_version_id,user_id,user_department_id,user_title_id ).count > 0
  end

  def same_record?
    sql = "docflow_version_id=#{docflow_version_id} AND ("
    conditions = []
    conditions << "user_id=#{user_id}" unless user_id.nil? # || user_id == ""
    conditions << "(user_department_id=#{user_department_id} AND user_title_id IS NULL)" if !user_department_id.nil? && user_title_id.nil?
    conditions << "(user_department_id IS NULL AND user_title_id=#{user_title_id})" if user_department_id.nil? && !user_title_id.nil?
    conditions << "(user_department_id=#{user_department_id} AND user_title_id=#{user_title_id})" if !user_department_id.nil? && !user_title_id.nil?
    conditions << "all_users='y'" if all_users == 'y'
    sql << conditions.join(" OR ") + ")"

    DocflowChecklist.where( sql ).count > 0 if conditions.any? 
  end

  def display_name
    full_name = ""
    if(!all_users.nil? && all_users == 'y')
      full_name = l(:label_docflows_all_users)
    elsif !user.nil?
      full_name = user.name
    elsif !department.nil?
      full_name = department.name
      full_name += ', '+title.name unless title.nil?
    elsif !title.nil?
      full_name = title.name
    elsif !group_set.nil?
      full_name = group_set.name      
    end
    return full_name
  end

end
