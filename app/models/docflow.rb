class Docflow < ActiveRecord::Base
  unloadable

  belongs_to :category, :class_name => "DocflowCategory", :foreign_key => :docflow_category_id
  belongs_to :type, :class_name =>"DocflowType", :foreign_key => :docflow_type_id
  belongs_to :responsible, :class_name => "User", :foreign_key => :responsible_id

  has_many :versions, :dependent => :destroy, :class_name => "DocflowVersion"#, :foreign_key => :docflow_version_id
  accepts_nested_attributes_for :versions

  validate :validate_fields

  attr_accessor :editable_version

  # last approved document, which actual_date older than current
  # select * FROM versions  WHERE status = approved AND actual_date >= current_date order by id (or approved_at) DESC Limit 1

  # todo: magick numbers in status comparements
  def current_version
    versions.where('docflow_status_id = ? AND actual_date <= ?', 3, Time.now).last # order(version)? or order(actual_from)?
  end

  # last approved document, not currently
  # todo: magick numbers in status comparements
  def actual_version
    versions.where(:docflow_status_id => 3).last
  end

  def last_version
    versions.order(:id).last
  end

  def first_version
    versions.order(:id).first
  end

  private

  def validate_fields
    # errors.add(:base, "Document has no files in editable version!") if editable_version.attachments.nil? || editable_version.attachments.empty?
    errors.add(:docflow_category_id, "Category should be defined!") if docflow_category_id.nil?
    errors.add(:docflow_type_id, "Type should be defined!") if docflow_type_id.nil?
    errors.add(:responsible_id, "Type should be defined!") if responsible_id.nil? || User.find(responsible_id).nil?
    errors.add(:title, "Title can't be empty!") if title.nil? || title == ""
  end
end
