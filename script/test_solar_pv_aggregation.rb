# test report manager
require 'ruby-prof'
require 'benchmark/memory'
require 'require_all'
require_relative '../lib/dashboard.rb'
require_rel '../test_support'
require './script/report_config_support.rb'

script = {
  logger1:                  { name: TestDirectoryConfiguration::LOG + "/pv %{time}.log", format: "%{severity.ljust(5, ' ')}: %{msg}\n" },
  # ruby_profiler:            true,
  schools:                  ['long*'],
  source:                   :unvalidated_meter_data,
  logger2:                  { name: "./log/reports %{school_name} %{time}.log", format: "%{datetime} %{severity.ljust(5, ' ')}: %{msg}\n" },
  reports:                  {
                              charts: [
                                adhoc_worksheet: { name: 'Test', charts: %i[
                                  schoolweek_alert_2_previous_holiday_comparison_adjusted
                                  ]},
                              ],
                              control: {
                                display_average_calculation_rate: true,
                                report_failed_charts:   :summary, 
                                compare_results:        [ 
                                  { comparison_directory: 'C:\Users\phili\Documents\TestResultsDontBackup\SolarPVAggregation\Base' },
                                  { output_directory:     'C:\Users\phili\Documents\TestResultsDontBackup\SolarPVAggregation\New' },
                                  :summary, 
                                  :quick_comparison,
                                ] 
                              }
                            }, 
}

RunTests.new(script).run
