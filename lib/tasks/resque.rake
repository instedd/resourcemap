require 'resque/tasks'
require 'resque/scheduler/tasks'

task "resque:setup" => :environment do
  builtin_queues = %w(email_queue sms_queue import_queue)
  plugin_schedule_queues = Plugin.hooks(:schedule).map { |x| x[:queue] }
  ENV['QUEUE'] ||= (builtin_queues + plugin_schedule_queues).join(',')
end
