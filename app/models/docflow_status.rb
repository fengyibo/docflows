class DocflowStatus < ActiveRecord::Base
  unloadable
  # todo: select status from DB where name=NEW. But this leds problem with in18
  # possible - is straight array
  DOCFLOW_STATUS_NEW = 1
end
