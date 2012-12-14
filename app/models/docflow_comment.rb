class DocflowComment < ActiveRecord::Base
  unloadable

  belongs_to :commentable, :polymorphic => true
  belongs_to :user

end