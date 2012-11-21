class Docflow < ActiveRecord::Base
  unloadable

  belongs_to :category, :class_name => "DocflowCategory", :foreign_key => :docflow_category_id
  belongs_to :type, :class_name =>"DocflowType", :foreign_key => :docflow_type_id
  belongs_to :responsible, :class_name => "User", :foreign_key => :responsible_id

  has_many :versions, :dependent => :destroy, :class_name => "DocflowVersion"#, :foreign_key => :docflow_version_id
  accepts_nested_attributes_for :versions

  validate :validate_fields

  attr_accessor :editable_version

  def self.ldap_users_sync_plugin?
    true if Kernel.const_get('GroupSet')
  rescue NameError
    false
  end

  # todo: magick numbers in status comparements

  def canceled?
    !last_version.nil? && last_version.docflow_status_id == 4
  end

  # last approved document, which actual_date older than current
  # select * FROM versions  WHERE status = approved AND actual_date >= current_date order by id (or approved_at) DESC Limit 1
  def current_version
    canceled? ? nil : versions.where('docflow_status_id = ? AND actual_date <= ?', 3, Time.now).order(:id).last
  end

  # last approved document, but not current
  def actual_version
    canceled? ? nil : versions.where(:docflow_status_id => 3).order(:id).last
  end

  def last_version
    versions.order(:id).last
  end

  def first_version
    versions.order(:id).first
  end

  private

  def validate_fields
    errors.add(:base, l(:label_docflow_permissions_cant_save_document)) unless User.current.edit_docflows? || User.current.edit_docflows_in_category?(docflow_category_id)
    # errors.add(:base, l(:label_docflow_permissions_cant_save_document_in_category)) unless User.current.edit_docflows_in_category?(docflow_category_id)
    errors.add(:docflow_category_id, l(:label_docflow_category_undefined)) if docflow_category_id.nil?
    errors.add(:docflow_type_id, l(:label_docflow_type_undefined)) if docflow_type_id.nil?
    errors.add(:responsible_id, l(:label_docflow_responsible_undefined)) if responsible_id.nil? || User.find(responsible_id).nil?
    errors.add(:title, l(:label_docflow_title_undefined)) if title.nil? || title == ""
  end
end
