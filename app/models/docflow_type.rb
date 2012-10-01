class DocflowType < ActiveRecord::Base
  unloadable
  has_many :docflows

  before_destroy :validates_docflows

  def validates_docflows
    errors.add(:base,l(:label_docflow_cant_delete_type_while_docflows_exists)) if docflows.any?
    errors.blank?
  end

end
