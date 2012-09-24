class DocflowFamiliarization < ActiveRecord::Base
  unloadable

  belongs_to :user
  belongs_to :version, :class_name => "DocflowVersion", :foreign_key => :docflow_version_id

  validate :validate_rec

  def validate_rec
    errors.add(:user_id, "User not defined!") if self.user_id.nil? || User.find(user_id).nil?
    errors.add(:docflow_version_id, "Document for familiarizatiation no selected!") if self.docflow_version_id.nil? || DocflowVersion.find(docflow_version_id).nil?
    errors.add(:done_date, "Familiarizatiation date can't be null") if self.done_date.nil?

    errors.add(:base,"Such user already has been learned this version of document") if DocflowFamiliarization.where('user_id=? and docflow_version_id=?',self.user_id,self.docflow_version_id).any?
  end
end
