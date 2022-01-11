require 'require_all'
require_relative '../../lib/dashboard.rb'
require_rel '../../test_support'

script = {
  logger1:                  { name: TestDirectoryConfiguration::LOG + "/datafeeds %{time}.log", format: "%{severity.ljust(5, ' ')}: %{msg}\n" },
  # ruby_profiler:            true,
  schools:                  ['king-j*', 'belv*', 'marksb*'],
  source:                   :unvalidated_meter_data,
  logger2:                  { name: "./log/reports %{school_name} %{time}.log", format: "%{datetime} %{severity.ljust(5, ' ')}: %{msg}\n" },
  alerts:                   {
    alerts:   [ AlertGasHeatingHotWaterOnDuringHoliday, AlertStorageHeaterHeatingOnDuringHoliday ],
    # alerts: nil,
    control:  {
                compare_results: {
                  summary:              :differences, # true || false || :detail || :differences
                  report_if_differs:    true,
                  methods:              %i[raw_variables_for_saving],   # %i[ raw_variables_for_saving front_end_template_data front_end_template_chart_data front_end_template_table_data
                  class_methods:        %i[front_end_template_variables],
                  comparison_directory: ENV['ANALYTICSTESTRESULTDIR'] + '\Alerts\Base',
                  output_directory:     ENV['ANALYTICSTESTRESULTDIR'] + '\Alerts\New'
                },

                no_save_priority_variables:  { filename: './TestResults/alert priorities.csv' },
                no_benchmark:          %i[school alert ], # detail],
                # asof_date:          (Date.new(2018,6,14)..Date.new(2019,6,14)).each_slice(7).map(&:first),
               asof_date:      Date.new(2022, 1, 2)
              }
  }
}

RunTests.new(script).run
