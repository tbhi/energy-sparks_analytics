require 'require_all'
require_relative '../../lib/dashboard.rb'
require_rel '../../test_support'
ENV['ENERGYSPARKSTESTMODE'] = 'ON'

module Logging
  @logger = Logger.new(File.join('log', 'benchmarks.log'))
  logger.level = :error
end

run_date = Date.new(2023,6,9)

overrides = {
  schools: ['*'], # ['king-ja*', 'crook*', 'hunw*', 'combe*'], # ['king-james-e*', 'wyb*', 'batheas*', 'the-dur*'], # ['shrew*', 'bathamp*'],
  cache_school: false,
  benchmarks: {
    calculate_and_save_variables: true,
    asof_date: run_date,
    pages: %i[
      solar_pv_benefit_estimate
    ],
    run_content: { asof_date: run_date } # , filter: ->{ !gpyc_difp.nil? && !gpyc_difp.infinite?.nil? } }
  }
}

script = RunBenchmarks.default_config.deep_merge(overrides)

RunTests.new(script).run
