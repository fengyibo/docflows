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
    end

  end
end