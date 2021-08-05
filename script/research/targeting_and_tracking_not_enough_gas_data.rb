# targeting and tracking covid/shortage of data stats for keeping track of progress
require 'require_all'
require_relative '../../lib/dashboard.rb'
require_rel '../../test_support'

module Logging
  @logger = Logger.new('log/targetting stats' + Time.now.strftime('%H %M') + '.log')
  logger.level = :debug
end

def school_factory
  $SCHOOL_FACTORY ||= SchoolFactory.new
end

def analyse_gas_meter(meter)
  puts "Analysing #{meter.mpxn}"
  puts "sd #{meter.amr_data.start_date} ed #{meter.amr_data.end_date}"
  puts "d1 #{meter.amr_data.keys.sort.first} d2 #{meter.amr_data.keys.sort.last}"
  estimate = MissingGasEstimation.new(meter, meter.annual_kwh_estimate)
  puts "Using method #{estimate.methodology}"
  puts "Total kwh = #{estimate.complete_year_amr_data.total}, estimate #{meter.annual_kwh_estimate}"
end

school_name_pattern_match = ['mundella*']
source_db = :unvalidated_meter_data

school_names = RunTests.resolve_school_list(source_db, school_name_pattern_match)

schools = school_names.map do |school_name|
  school_factory.load_or_use_cached_meter_collection(:name, school_name, source_db)
end

schools.each do |school|
  meter = school.aggregate_meter(:gas)
  unless meter.nil?
    analyse_gas_meter(meter)
  end
end
