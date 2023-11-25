require 'active_record_telemetry'

class ApplicationRecord < ActiveRecord::Base
  include ActiveRecordTelemetry
  self.abstract_class = true
end
