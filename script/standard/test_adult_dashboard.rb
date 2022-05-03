require 'require_all'
require_relative '../../lib/dashboard.rb'
require_all './test_support/'

module Logging
  @logger = Logger.new('log\logs.log')
  logger.level = :error
end

overrides = {
  schools: ['*'], # ['bxxxxalli*', 'wimble*'],
  # adult_dashboard: { control: { pages: %i[boiler_control_morning_start_time], user: { user_role: :analytics, staff_role: nil } } }
  # adult_dashboard: { control: { pages: %i[ gas_target] } }
}

script = RunAdultDashboard.default_config.deep_merge(overrides)

RunTests.new(script).run
