# Centrica
require 'require_all'
require_relative '../../lib/dashboard.rb'
require_rel '../../test_support'

module Logging
  @logger = Logger.new('log/chart-y_axis_manipulation ' + Time.now.strftime('%H %M') + '.log')
  @logger.level = :debug # :debug
end

school_name_pattern_match = ['king-j*']
source_db = :unvalidated_meter_data
chart_name = :gas_longterm_trend
charts = []

school_name = RunTests.resolve_school_list(source_db, school_name_pattern_match).first
school = SchoolFactory.new.load_or_use_cached_meter_collection(:name, school_name, source_db)
chart_manager = ChartManager.new(school)
  
puts "School: #{school_name}"
puts "Chart: #{chart_name}"

existing_chart_config = ChartManager::STANDARD_CHART_CONFIGURATION[chart_name]

ChartYAxisManipulation.new(school).y1_axis_choices(existing_chart_config).each do |y1_axis_unit|
  chart_config = ChartYAxisManipulation.new(school).change_y1_axis_config(existing_chart_config, y1_axis_unit)
  chart_data = chart_manager.run_chart(chart_config, chart_name)
  charts.push(chart_data)
end

ChartYAxisManipulation.new(school).y2_axis_choices(existing_chart_config).each do |y2_axis_unit|
  chart_config = ChartYAxisManipulation.new(school).change_y2_axis_config(existing_chart_config, y2_axis_unit)
  chart_data = chart_manager.run_chart(chart_config, chart_name)
  charts.push(chart_data)
end

puts 'Testing exception checking:'
begin
  chart_config = ChartYAxisManipulation.new(school).change_y1_axis_config(existing_chart_config, :rubbish)
rescue ChartYAxisManipulation::CantChangeY1AxisException => e
  puts e.message
end

begin
  chart_config = ChartYAxisManipulation.new(school).change_y2_axis_config(existing_chart_config, :rubbish)
rescue ChartYAxisManipulation::CantChangeY2AxisException => e
  puts e.message
end

filename = 'Results\\test-y-axis-manipulation.xlsx'

puts "Saving results to #{filename}"

excel = ExcelCharts.new(filename)

excel.add_charts('Test', charts)

excel.close
