require 'require_all'
require_relative '../../lib/dashboard.rb'
require_rel '../../test_support'

def example_manually_configured_scenarios
  [
    { fuel_types: %i[electricity gas], target: 0.95 },
    { target_start_date:  -7, truncate_amr_data: 365 * 2, move_end_date: -90,  fuel_types: %i[electricity gas], target: 0.95 },
    { target_start_date:  -7, truncate_amr_data: 365 * 2, move_end_date: -90,  fuel_types: %i[electricity gas], target: 0.95 },
    { target_start_date:  -7, truncate_amr_data: 365 * 1, move_end_date:   0,  fuel_types: %i[electricity gas], target: 0.90 },
    { target_start_date:  -7, truncate_amr_data: 365 * 1, move_end_date: -180, fuel_types: %i[electricity gas], target: 0.90 },
  ]
end

def test_heating_temperature_compensation_scenarios
  [
    # move target date back to mid winter, so about 50% of target already
    # past, so temperature compensated, but leaving a remaining 50%
    # on uncompensated future target
    { target_start_date:  Date.new(Date.today.year,     1, 8), fuel_types: %i[electricity gas], target: 0.95 },
    { target_start_date:  Date.new(Date.today.year - 1, 9, 1), fuel_types: %i[electricity gas], target: 0.95 },
    { target_start_date:  Date.new(Date.today.year    , 7, 1), fuel_types: %i[electricity gas], target: 0.95 },
  ]
end

def example_central_case_scenario
  [
    { fuel_types: %i[electricity gas], target: 0.95 }
  ]
end

def script(scenarios)
  control = RunTargetingAndTracking.default_control_settings.deep_merge({ control: {scenarios: scenarios}})
  {
    logger1:                { name: TestDirectoryConfiguration::LOG + "/test targeting and tracking %{time}.log", format: "%{severity.ljust(5, ' ')}: %{msg}\n" },

    schools:  ['*'], # ['glyn*', 'pentrech*', 'west-w*'],
    schools: ['belv*', 'howel*', 'hXt*', 'nottXing-h*', 'portsm*', 'put*', 'roya*',
      'shrew*','south-hamp*', 'st-bede*', 'st-lou*', 'wimbl*'],

    schools: ['putney*'],
    schools: ['howel*', 'ht*', 'notting-h*'],
    schools: ['ht*'],


    source:                 :unvalidated_meter_data,

    logger2:                { name: TestDirectoryConfiguration::LOG + "/targeting and tracking %{school_name} %{time}.log", format: "%{datetime} %{severity.ljust(5, ' ')}: %{msg}\n" },

    targeting_and_tracking: control
  }
end

RunTests.new(script(example_central_case_scenario)).run
