class DocflowStatus < ActiveRecord::Base
  unloadable
  # todo: select status from DB where name=NEW. But this leds problem with in18
  # possible - is straight array
  DOCFLOW_STATUS_NEW          = 1
  DOCFLOW_STATUS_TO_APPROVIAL = 2
  DOCFLOW_STATUS_APPROVED     = 3
  DOCFLOW_STATUS_CANCELED     = 4
end
