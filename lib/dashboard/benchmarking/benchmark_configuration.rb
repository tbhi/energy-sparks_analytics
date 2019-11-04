require_relative './benchmark_content_base.rb'
module Benchmarking
  class BenchmarkManager

    def self.chart_table_config(name)
      config = CHART_TABLE_CONFIG[name]
    end

    def self.chart_column?(column_definition)
      y1_axis_column?(column_definition) || y2_axis_column?(column_definition)
    end

    def self.y1_axis_column?(column_definition)
      column_definition?(column_definition, :chart_data) && !y2_axis_column?(column_definition)
    end

    def self.y2_axis_column?(column_definition)
      column_definition?(column_definition, :y2_axis)
    end

    def self.has_y2_column?(definition)
      definition[:columns].any? { |column_definition| y2_axis_column?(column_definition) }
    end

    def self.column_definition?(column_definition, key)
      column_definition.key?(key) && column_definition[key]
    end

    def self.available_pages
      all_pages = CHART_TABLE_CONFIG.clone
      all_pages.transform_values{ |config| config[:name] }
    end

    CHART_TABLE_CONFIG = {
      annual_electricity_costs_per_pupil: {
        benchmark_class:  BenchmarkContentElectricityPerPupil,
        name:     'Annual electricity use per pupil (excluding storage heaters)',
        columns:  [
          { data: 'addp_name',      name: 'School name', units: String, chart_data: true },
          { data: ->{ elba_£pup },  name: 'Annual electricity GBP/pupil', units: :£, chart_data: true },
          { data: ->{ elba_£lyr },  name: 'Annual electricity GBP', units: :£},
          { data: ->{ elba_£esav }, name: 'Saving if matched exemplar school', units: :£ },
          { data: ->{ elba_ratg },  name: 'rating', units: Float, y2_axis: true },
        ],
        sort_by:  [1], # column 1 i.e. Annual kWh
        type: %i[chart table]
      },
      change_in_annual_electricity_consumption: {
        name:     'Change in annual electricity consumption (excluding storage heaters)',
        columns:  [
          { data: 'addp_name',      name: 'School name', units: String, chart_data: true },
          { data: ->{ (elba_£lyr - elba_£lyr_last_year) / elba_£lyr_last_year},  name: 'Change in annual electricity usage', units: :percent, chart_data: true },
          { data: ->{ elba_£lyr },  name: 'Annual electricity GBP (this year)', units: :£},
          { data: ->{ elba_£lyr_last_year },  name: 'Annual electricity GBP (last year)', units: :£}
        ],
        sort_by:  [1], # column 1 i.e. Annual kWh
        type: %i[chart table]
      },
      annual_electricity_out_of_hours_use: {
        name:     'Electricity out of hours use',
        columns:  [
          { data: 'addp_name',      name: 'School name',                  units: String, chart_data: true   },
          { data: ->{ eloo_sdop },  name: 'School day open',              units: :percent, chart_data: true },
          { data: ->{ eloo_sdcp },  name: 'School day closed',            units: :percent, chart_data: true },
          { data: ->{ eloo_holp },  name: 'Holidays',                     units: :percent, chart_data: true },
          { data: ->{ eloo_wkep },  name: 'Weekends',                     units: :percent, chart_data: true },
          { data: ->{ eloo_aoo£ },  name: 'Annual out of hours cost',     units: :£ },
          { data: ->{ eloo_esv£ },  name: 'Saving if improve to exemplar',units: :£ },
          { data: ->{ eloo_ratg },  name: 'rating',                       units: Float, y2_axis: true }
        ],
        sort_by:  [1],
        type: %i[chart table]
      },
      recent_change_in_baseload: {
        name:     'Last week\'s baseload versus average of last year (% difference)',
        columns:  [
          { data: 'addp_name', name: 'School name', units: String, chart_data: true },
          { data: ->{ elbc_bspc }, name: 'Change in baseload last week v. year percent', units: :percent, chart_data: true},
          { data: ->{ elbc_blly }, name: 'Average baseload last year kW', units: :kw},
          { data: ->{ elbc_bllw }, name: 'Average baseload last week kW', units: :kw},
          { data: ->{ elbc_blch }, name: 'Change in baseload last week v. year kW', units: :kw},
          { data: ->{ elbc_ratg },  name: 'rating', units: Float, y2_axis: true }
        ],
        sort_by:  [1],
        type: %i[chart table]
      },
      baseload_per_pupil: {
        name:     'Baseload per pupil',
        columns:  [
          { data: 'addp_name', name: 'School name', units: String, chart_data: true },
          { data: ->{ elbb_blpp }, name: 'Baseload per pupil (kW)', units: :kw, chart_data: true},
          { data: ->{ elbb_lygb }, name: 'Annual cost of baseload', units: :£},
          { data: ->{ elbb_lykw }, name: 'Average baseload kW', units: :kw},
          { data: ->{ elbb_ratg },  name: 'rating', units: Float, y2_axis: true }
        ],
        sort_by:  [1],
        type: %i[chart table]
      },
      hot_water_efficiency: {
        name:     'Hot Water Efficiency',
        columns:  [
          { data: 'addp_name',      name: 'School name', units: String, chart_data: true },
          { data: ->{ hotw_ppyr },  name: 'Cost per pupil', units: :£, chart_data: true},
          { data: ->{ hotw_eff  },  name: 'Efficiency of system', units: :percent},
          { data: ->{ hotw_gsav },  name: 'Saving improving timing', units: :£},
          { data: ->{ hotw_esav },  name: 'Saving with POU electric hot water', units: :£},
          { data: ->{ hotw_ratg },  name: 'rating', units: Float, y2_axis: true }
        ],
        sort_by:  [1],
        type: %i[chart table]
      },
      annual_gas_costs_per_floor_area: {
        name:     'Annual heating cost per floor area (temperature compensated)',
        columns:  [
          { data: 'addp_name',      name: 'School name',    units: String, chart_data: true },
          { data: ->{ sum_data([gsba_pfla, shan_pfla], true)  * 2000.0 / addp_ddays },   name: 'Annual gas/storage heater GBP/pupil (temp compensated)', units: :£, chart_data: true },
          { data: ->{ sum_data([gsba_£lyr, shan_£lyr], true) },  name: 'Annual cost GBP', units: :£},
          { data: ->{ sum_data([gsba_pfla, shan_pfla], true) - 
                        (sum_data([gsba_£exa, shan_£exa], true) * addp_ddays / 2000.0) }, name: 'Saving if matched exemplar school', units: :£ },
          { data: ->{ or_nil([gsba_ratg, shan_ratg]) },  name: 'rating', units: Float, y2_axis: true }
        ],
        sort_by:  [1],
        type: %i[chart table]
      },
      change_in_annual_gas_consumption: {
        name:     'Change in annual gas consumption',
        columns:  [
          { data: 'addp_name',      name: 'School name', units: String, chart_data: true },
          { data: ->{ percent_change([gsba_£lyr_last_year, shan_£lyr_last_year], [gsba_£lyr, shan_£lyr], true) },  name: 'Change in annual gas/storage heater usage', units: :percent, chart_data: true },
          { data: ->{ gsba_£lyr },  name: 'Annual gas GBP (this year)', units: :£},
          { data: ->{ gsba_£lyr_last_year },  name: 'Annual gas GBP (last year)', units: :£}
        ],
        sort_by:  [1], # column 1 i.e. Annual kWh
        type: %i[chart table]
      },
      annual_gas_out_of_hours_use: {
        name:     'Gas out of hours use',
        columns:  [
          { data: 'addp_name',      name: 'School name',                  units: String,   chart_data: true },
          { data: ->{ gsoo_sdop },  name: 'School day open',              units: :percent, chart_data: true },
          { data: ->{ gsoo_sdcp },  name: 'School day closed',            units: :percent, chart_data: true },
          { data: ->{ gsoo_holp },  name: 'Holidays',                     units: :percent, chart_data: true },
          { data: ->{ gsoo_wkep },  name: 'Weekends',                     units: :percent, chart_data: true },
          { data: ->{ gsoo_aoo£ },  name: 'Annual out of hours cost',     units: :£ },
          { data: ->{ gsoo_esv£ },  name: 'Saving if improve to exemplar',units: :£ },
          { data: ->{ gsoo_ratg },  name: 'rating', units: Float, y2_axis: true }
        ],
        sort_by:  [1],
        type: %i[chart table]
      },
      annual_storage_heater_out_of_hours_use: {
        name:     'Storage heater out of hours use',
        columns:  [
          { data: 'addp_name',      name: 'School name',                  units: String,   chart_data: true },
          { data: ->{ shoo_sdop },  name: 'School day open',              units: :percent, chart_data: true },
          { data: ->{ shoo_sdcp },  name: 'School day closed',            units: :percent, chart_data: true },
          { data: ->{ shoo_holp },  name: 'Holidays',                     units: :percent, chart_data: true },
          { data: ->{ shoo_wkep },  name: 'Weekends',                     units: :percent, chart_data: true },
          { data: ->{ shoo_aoo£ },  name: 'Annual out of hours cost',     units: :£ },
          { data: ->{ shoo_esv£ },  name: 'Saving if improve to exemplar',units: :£ },
          { data: ->{ shoo_ratg },  name: 'rating', units: Float, y2_axis: true }
        ],
        sort_by:  [1],
        type: %i[chart table]
      },
      heating_coming_on_too_early: {
        name:     'Heating start time (potentially coming on too early in morning)',
        columns:  [
          { data: 'addp_name',      name: 'School name',                  units: String,   chart_data: true },
          { data: ->{ hthe_htst },  name: 'Average heating start time (last week)', units: :timeofday, chart_data: true },
          { data: ->{ hthe_oss£ },  name: 'Annual saving if improve to exemplar',units: :£ },
          { data: ->{ hthe_ratg },  name: 'rating', units: Float, y2_axis: true }
        ],
        sort_by:  [1],
        type: %i[chart table]
      },
      thermostat_sensitivity: {
        name:     'Annual saving through 1C reduction in thermostat temperature',
        columns:  [
          { data: 'addp_name',      name: 'School name',                  units: String,   chart_data: true },
          { data: ->{ htsa_td1c },  name: 'Annual saving per 1C reduction in thermostat', units: :£, chart_data: true },
          { data: ->{ htsa_ratg },  name: 'rating', units: Float, y2_axis: true }
        ],
        sort_by:  [1],
        type: %i[chart table]
      },
      length_of_school_day_heating_season: {
        name:     'Number of days heating was on last year',
        columns:  [
          { data: 'addp_name',                   name: 'School name',           units: String, chart_data: true },
          { data: ->{ addp_area.split(' ')[0] }, name: 'Area',                  units: String },
          { data: ->{ htsd_hdyr },  name: 'No. days heating on last year', units: :days, chart_data: true },
          { data: ->{ htsd_svav },  name: 'Saving through reducing season to average', units: :£ },
          { data: ->{ htsd_svex },  name: 'Saving through reducing season to exemplar', units: :£ },
          { data: ->{ htsd_svep },  name: 'Saving through reducing season to exemplar', units: :percent },
          { data: ->{ htsd_ratg },  name: 'rating', units: Float, y2_axis: true }
        ],
        number_non_null_columns_for_filtering_tables: 3,
        sort_by: [1, 2],
        type: %i[chart table]
      },
      thermostatic_control: {
        name:     'Quality of thermostatic control (R2 close to 1.0 is good)',
        columns:  [
          { data: 'addp_name',      name: 'School name',     units: String, chart_data: true },
          { data: ->{ or_nil([httc_r2, shtc_r2]) },    name: 'Thermostatic R2', units: Float,  chart_data: true },
          { data: ->{ sum_data([httc_sav£, shtc_sav£], true) },  name: 'Saving through improved thermostatic control', units: :£ },
          { data: ->{ httc_ratg },  name: 'rating', units: Float, y2_axis: true }
        ],
        sort_by: [1],
        type: %i[chart table]
      },
      electricity_meter_consolidation_opportunities: {
        name:     'Opportunities for electricity meter consolidation',
        columns:  [
          { data: 'addp_name',      name: 'School name',     units: String, chart_data: true },
          { data: ->{ emtc_sav£ },  name: 'Potential max annual saving £', units: :£,  chart_data: true },
          { data: ->{ emtc_mets },  name: 'Number of electricity meters', units: :meters },
          { data: ->{ emtc_ratg },  name: 'rating', units: Float, y2_axis: true }
        ],
        sort_by: [1],
        type: %i[table chart]
      },
      gas_meter_consolidation_opportunities: {
        name:     'Opportunities for gas meter consolidation',
        columns:  [
          { data: 'addp_name',      name: 'School name',     units: String, chart_data: true },
          { data: ->{ gmtc_sav£ },  name: 'Potential max annual saving £', units: :£,  chart_data: true },
          { data: ->{ gmtc_mets },  name: 'Number of gas meters', units: :meters },
          { data: ->{ gmtc_ratg },  name: 'rating', units: Float, y2_axis: true }
        ],
        sort_by: [1],
        type: %i[table chart]
      },
      differential_tariff_opportunity: {
        name:     'Benefit of moving to or away from differential tariff',
        columns:  [
          { data: 'addp_name',      name: 'School name',     units: String, chart_data: true },
          { data: ->{ dtaf_sav£ },  name: 'Potential annual saving £', units: :£,  chart_data: true },
          { data: ->{ dtaf_ratg },  name: 'rating', units: Float, y2_axis: true }
        ],
        sort_by: [1],
        type: %i[table chart]
      },
      change_in_electricity_consumption_recent_school_weeks: {
        name:     'Change in electricity consumption since last school week',
        columns:  [
          { data: 'addp_name',      name: 'School name',     units: String, chart_data: true },
          { data: ->{ eswc_difp },  name: 'Change %', units: :percent, chart_data: true },
          { data: ->{ eswc_dif£ },  name: 'Change £', units: :£ },
        ],
        sort_by: [1],
        type: %i[table chart]
      },
      change_in_electricity_holiday_consumption_previous_holiday: {
        name:     'Change in electricity consumption between the 2 most recent holidays',
        columns:  [
          { data: 'addp_name',      name: 'School name',     units: String, chart_data: true },
          { data: ->{ ephc_difp },  name: 'Change %', units: :percent, chart_data: true },
          { data: ->{ ephc_dif£ },  name: 'Change £', units: :£ },
          { data: ->{ ephc_ratg },  name: 'rating', units: Float, y2_axis: true }
        ],
        sort_by: [1],
        type: %i[table chart]
      },
      change_in_electricity_holiday_consumption_previous_years_holiday: {
        name:     'Change in electricity consumption between this holiday and the same the previous year',
        columns:  [
          { data: 'addp_name',      name: 'School name',     units: String, chart_data: true },
          { data: ->{ epyc_difp },  name: 'Change %', units: :percent, chart_data: true },
          { data: ->{ epyc_dif£ },  name: 'Change £', units: :£ },
          { data: ->{ epyc_ratg },  name: 'rating', units: Float, y2_axis: true }
        ],
        sort_by: [1],
        type: %i[table chart]
      },
      change_in_gas_consumption_recent_school_weeks: {
        name:     'Change in gas consumption since last school week',
        columns:  [
          { data: 'addp_name',      name: 'School name',     units: String, chart_data: true },
          { data: ->{ gswc_difp },  name: 'Change %', units: :percent, chart_data: true },
          { data: ->{ gswc_dif£ },  name: 'Change £', units: :£ },
          { data: ->{ gswc_ratg },  name: 'rating', units: Float, y2_axis: true }
        ],
        sort_by: [1],
        type: %i[table chart]
      },
      change_in_gas_holiday_consumption_previous_holiday: {
        name:     'Change in gas consumption between the 2 most recent holidays',
        columns:  [
          { data: 'addp_name',      name: 'School name',     units: String, chart_data: true },
          { data: ->{ gphc_difp },  name: 'Change %', units: :percent, chart_data: true },
          { data: ->{ gphc_dif£ },  name: 'Change £', units: :£ },
          { data: ->{ gphc_ratg },  name: 'rating', units: Float, y2_axis: true }
        ],
        sort_by: [1],
        type: %i[table chart]
      },
      change_in_gas_holiday_consumption_previous_years_holiday: {
        name:     'Change in gas consumption between this holiday and the same the previous year',
        columns:  [
          { data: 'addp_name',      name: 'School name',     units: String, chart_data: true },
          { data: ->{ gpyc_difp },  name: 'Change %', units: :percent, chart_data: true },
          { data: ->{ gpyc_dif£ },  name: 'Change £', units: :£ },
          { data: ->{ gpyc_ratg },  name: 'rating', units: Float, y2_axis: true }
        ],
        sort_by: [1],
        type: %i[table chart]
      },
      electricity_peak_kw_per_pupil: {
        name:     'Peak school day electricity comparison kW/floor area',
        columns:  [
          { data: 'addp_name',      name: 'School name',      units: String, chart_data: true },
          { data: ->{ epkb_kwfa },  name: 'kW/floor area',    units: :kw, chart_data: true },
          { data: ->{ epkb_kwsc },  name: 'average peak kw',  units: :kw },
          { data: ->{ epkb_kwex },  name: 'exemplar peak kw', units: :kw },
          { data: ->{ epkb_tex£ },  name: 'saving if match exemplar (£)', units: :£ },
          { data: ->{ epkb_ratg },  name: 'rating', units: Float, y2_axis: true }
        ],
        sort_by: [1],
        type: %i[table chart]
      },
      solar_pv_benefit_estimate: {
        name:     'Benefit of estimated optimum size solar PV installation',
        columns:  [
          { data: 'addp_name',      name: 'School name',      units: String },
          { data: ->{ sole_opvk },  name: 'kWp',    units: :kwp},
          { data: ->{ sole_opvy },  name: 'payback (years)',  units: :years },
          { data: ->{ sole_opvp },  name: 'Percent reduction in mains consumption', units: :percent }
        ],
        sort_by: [1],
        type: %i[table]
      },
    }.freeze
=begin

      AlertSchoolWeekComparisonElectricity          => 'eswc',
      AlertPreviousHolidayComparisonElectricity     => 'ephc',
      AlertPreviousYearHolidayComparisonElectricity => 'epyc',
      AlertSchoolWeekComparisonGas                  => 'gswc',
      AlertPreviousHolidayComparisonGas             => 'gphc',
      AlertPreviousYearHolidayComparisonGas         => 'gpyc',

      AlertElectricityPeakKWVersusBenchmark         => 'epkb'

      AlertHeatingOnOff                             => 'htoo',
      AlertWeekendGasConsumptionShortTerm           => 'gswe',
      AlertMeterASCLimit                            => 'masc',
      AlertAdditionalPrioritisationData             => 'addp',
=end
  end
end
