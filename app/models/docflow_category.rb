class DocflowCategory < ActiveRecord::Base
  unloadable

  # Need not to change :dependent. Deprecate of deletion if any childs present
  # :dependent => :delete_all (default) No reason to check every subcategory.child on delete

  acts_as_nested_set

  belongs_to :department, :class_name => "UserDepartment", :foreign_key => :editor_department_id
  belongs_to :title, :class_name => "UserTitle", :foreign_key => :editor_title_id
  belongs_to :approver, :class_name => "User", :foreign_key => :default_approver_id

  has_many :docflows

  validate :validates_parent_id


  # Only redefine destory! No possibility of usage before_destroy :no_any_childs?
  # Proper decision about deletion is possible only before acts_as_nested_set.destroy runs!
  # before_destroy executing only on target object when all childs purged
  # interrupting of deletion in befor filter leds to nested_set (lft,rgt) crash!

  def destroy
    return super if no_any_childs?
  end

  private

  def validates_parent_id
    errors.add(:base, l(:label_docflow_category_parent_id_cant_be_same)) if (!parent_id.nil? && !id.nil? && (parent_id == id))
    errors.add(:parent_id, l(:label_docflow_category_does_not_exists)) if !parent_id.nil? && DocflowCategory.find(parent_id).nil?
  end


  def no_any_childs?
    errors.add(:base, l(:label_docflow_category_has_childs))  unless docflows.empty? and descendants.empty?
    errors.blank?
  end

end
