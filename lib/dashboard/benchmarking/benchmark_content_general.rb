require_relative './benchmark_no_text_mixin.rb'
require_relative './benchmark_content_base.rb'

module Benchmarking
  CAVEAT_TEXT = {
    es_doesnt_have_all_meter_data: %q(
      <p>
        The table provides the information in more detail.
        Energy Sparks doesn&apos;t have a full set of meter data
        for some schools, for example rural schools with biomass or oil boilers,
        so this comparison might not be relevant for all schools. The comparison
        excludes the benefit of any solar PV which might be installed - so looks
        at energy consumption only.
      </p>
    ),
    es_data_not_in_sync: %q(
      <p>
        The gas, electricity and storage heater costs are all using the latest
        data. The total might not be the sum of these 3 in the circumstance
        where one of the meter's data is out of date, and the total then covers the
        most recent year where all data is available to us on all the underlying
        meters, and hence will cover the period of the most out of date of the
        underlying meters.
      </p>
    ),
    es_per_pupil_v_per_floor_area: %q(
      <p>
          Generally, per pupil benchmarks are appropriate for electricity
          (should be proportional to the appliances e.g. ICT in use),
          but per floor area benchmarks are more appropriate for gas (size of
          building which needs heating). Overall, <u>energy</u> use comparison
          on a per pupil basis is probably more appropriate than on a per
          floor area basis, but this analysis can be useful in some circumstances.
      </p>
    ),
    es_exclude_storage_heaters_and_solar_pv: %q(
      <p>
        This breakdown excludes electricity consumed by storage heaters and
        solar PV.
      </p>
    ),
    comparison_with_previous_period_infinite: %q(
      <p>
        An infinite or uncalculable value indicates the consumption in the first period was zero.
      </p>
    ),
    es_sources_of_baseload_electricity_consumption: %q(
      <p>
        Consumers of out of hours electricity include
        <ul>
          <li>
            Equipment left on rather than being turned off, including
            photocopiers and ICT equipment
          </li>
          <li>
            ICT servers - can be inefficient, newer ones can often payback their
            capital costs in electricity savings within a few years, see our
            <a href="https://energysparks.uk/case_studies/4/link" target ="_blank">case study</a>
            on this
          </li>
          <li>
            Security lighting - this can be reduced by using PIR movement detectors
            - often better for security and by moving to more efficient LED lighting
          </li>
          <li>
            Fridges and freezers, particularly inefficient commercial kitchen appliances, which if
            replaced can provide a very short payback on investment (see
            our <a href="https://energysparks.uk/case_studies/1/link" target ="_blank">case study</a> on this).
          </li>
          <li>
            Hot water heaters and boilers left on outside school hours - installing a timer or getting
            the caretaker to switch these off when closing the school at night or on a Friday can
            make a big difference
          </li>
        </ul>
      <p>
    ),
    covid_lockdown: %q(),
    covid_lockdown_deprecated: %q(
      <p>
        This comparison may include COVID lockdown periods which may skew the results.
      </p>
    ),
    holiday_comparison: %q(),
    temperature_compensation: %q(
      <p>
        This comparison compares the latest available data for the most recent
        holiday with an adjusted figure for the previous holiday, scaling to the
        same number of days and adjusting for changes in outside temperature.
        The change in &pound; is the saving or increased cost for the most recent holiday to date.
      </p>
    ),
    holiday_length_normalisation: %q(
      <p>
        This comparison compares the latest available data for the most recent holiday
        with an adjusted figure for the previous holiday, scaling to the same number of days.
        The change in &pound; is the saving or increased cost for the most recent holiday to date.
      </p>
    ),
    last_year_previous_year_definition:  %q(
      <p>
        In school comparisons &apos;last year&apos; is defined as this year to date,
        &apos;previous year&apos; is defined as the year before.
      </p>
    ),
    last_year_definition:  %q(
      <p>
        In school comparisons &apos;last year&apos; is defined as this year to date.
      </p>
    )
  }
  #=======================================================================================
  class BenchmarkContentEnergyPerPupil < BenchmarkContentBase
    include BenchmarkingNoTextMixin

    private def introduction_text
      text =  I18n.t('analytics.benchmarking.content.annual_energy_costs_per_pupil.introduction_text_html')
      text += I18n.t('analytics.benchmarking.caveat_text.es_per_pupil_v_per_floor_area_html')
      text += I18n.t('analytics.benchmarking.caveat_text.es_doesnt_have_all_meter_data_html')
      ERB.new(text).result(binding)
    end
  end
  #=======================================================================================
  class BenchmarkContentTotalAnnualEnergy < BenchmarkContentBase
    include BenchmarkingNoTextMixin
    private def introduction_text
      text = I18n.t('analytics.benchmarking.content.annual_energy_costs.introduction_text_html')
      text += I18n.t('analytics.benchmarking.caveat_text.es_doesnt_have_all_meter_data_html')
      ERB.new(text).result(binding)
    end
    # private def table_introduction_text
    #   I18n.t('analytics.benchmarking.caveat_text.es_doesnt_have_all_meter_data_html')
    # end
    protected def table_interpretation_text
      I18n.t('analytics.benchmarking.caveat_text.es_data_not_in_sync_html')
    end
  end
  #=======================================================================================
  class BenchmarkContentElectricityPerPupil < BenchmarkContentBase
    include BenchmarkingNoTextMixin
    private def introduction_text
      I18n.t('analytics.benchmarking.content.annual_electricity_costs_per_pupil.introduction_text_html')
    end
  end
  #=======================================================================================
  class BenchmarkContentChangeInAnnualElectricityConsumption < BenchmarkContentBase
    include BenchmarkingNoTextMixin
    private def introduction_text
      %q(
        <p>
          This benchmark shows the change in electricity consumption between
          last year and the previous year, excluding solar PV and storage heaters.
        </p>
        <p>
          Schools should be aiming to reduce their electricity consumption by
          about 5% per year because most equipment used by schools is getting
          more efficient, for example a desktop computer might use 150W, a laptop
          20W and a tablet 2W. Switching from using desktops to tablets reduces
          their electricity consumption by a factor of 75. LED lighting can be
          2 to 3 times for efficient than older florescent lighting.
        </p>
        <p>
          To make a significant contribution to mitigating climate
          change schools should really be aiming to reduce their electricity
          consumption by 10% year on year to meet the UK&apos;s climate change obligations
          - something which is easily achievable
          through a mixture of behavioural change and tactical investment in
          more efficient equipment.
        </p>
        <p>
          An increase in electricity consumption, unless there has been a significant
          increase in pupil numbers is inexcusable if a school is planning on contributing
          to reducing global carbon emissions.
        </p>
      ) + CAVEAT_TEXT[:covid_lockdown]
    end
  end
  #=======================================================================================
  class BenchmarkContentElectricityOutOfHoursUsage < BenchmarkContentBase
    include BenchmarkingNoTextMixin

    private def introduction_text
      text = I18n.t('analytics.benchmarking.content.annual_electricity_out_of_hours_use.introduction_text_html')
      text += I18n.t('analytics.benchmarking.caveat_text.es_exclude_storage_heaters_and_solar_pv_html')
      ERB.new(text).result(binding)
    end
  end
  #=======================================================================================
  class BenchmarkBaseloadBase < BenchmarkContentBase   
    def content(school_ids: nil, filter: nil, user_type: nil)
      @baseload_impact_html = baseload_1_kw_change_range_£_html(school_ids, filter, user_type)
      super(school_ids: school_ids, filter: filter)
    end

    private

    def baseload_1_kw_change_range_£_html(school_ids, filter, user_type)
      cost_of_1_kw_baseload_range_£ = calculate_cost_of_1_kw_baseload_range_£(school_ids, filter, user_type)

      cost_of_1_kw_baseload_range_£_html = cost_of_1_kw_baseload_range_£.map do |costs_£|
        FormatEnergyUnit.format(:£, costs_£, :html)
      end

      text = %q(
        <p>
          <% if cost_of_1_kw_baseload_range_£_html.empty? %>

          <% elsif cost_of_1_kw_baseload_range_£_html.length == 1 %>
            A 1 kW increase in baseload is equivalent to an increase in
            annual electricity costs of <%= cost_of_1_kw_baseload_range_£_html.first %>.
          <% else %>
            A 1 kW increase in baseload is equivalent to an increase in
            annual electricity costs of between <%= cost_of_1_kw_baseload_range_£_html.first %>
            and <%= cost_of_1_kw_baseload_range_£_html.last %> depending on your current tariff.
          <% end %>    
        </p>
      )
      ERB.new(text).result(binding)
    end

    def calculate_cost_of_1_kw_baseload_range_£(school_ids, filter, user_type)
      rates = calculate_blended_rate_range(school_ids, filter, user_type)

      hours_per_year = 24.0 * 365
      rates.map { |rate| rate * hours_per_year }
    end

    def calculate_blended_rate_range(school_ids, filter, user_type)
      col_index = column_headings(school_ids, filter, user_type).index(:blended_current_rate)
      data = raw_data(school_ids, filter, user_type)
      return [] if data.nil? || data.empty?

      blended_rate_per_kwhs = data.map { |row| row[col_index] }.compact

      blended_rate_per_kwhs.map { |rate| rate.round(2) }.minmax.uniq
    end
  end

  #=======================================================================================
  class BenchmarkContentChangeInBaseloadSinceLastYear < BenchmarkBaseloadBase
    include BenchmarkingNoTextMixin

    def introduction_text
      text = %q(
        <p>
          This benchmark compares a school&apos;s current baseload (electricity
          consumed when the school is closed) with that of the average
          of the last year. Schools should be aiming to reduce baseload over time
          and not increase it as equipment and lighting has become significantly
          more efficient over the last few years. Any increase should be tracked
          down as soon as it is discovered. Energy Sparks can be configured
          to send you an alert via an email or a text message if it detects
          this has happened.
        </p>
        <%= @baseload_impact_html %>
        <%= CAVEAT_TEXT[:es_exclude_storage_heaters_and_solar_pv] %>
        <%= CAVEAT_TEXT[:covid_lockdown] %>
      )
      ERB.new(text).result(binding)
    end
  end
  #=======================================================================================
  class BenchmarkRefrigeration < BenchmarkContentBase
    include BenchmarkingNoTextMixin

    def self.intro
      text = %q(
        <p>
          This benchmark looks at any overnight reduction in electricity consumption
          during the last summer holidays and assumes this is mainly from refrigeration
          being turned off, using this information to assess the efficiency of schools&apos
          refrigeration.
        </p>
        <p>
          The analysis is experimental and can create false positives.
          If no impact is detected either the school didn&apos;t
          turn their fridges and freezers off during the summer holidays
          or they are very efficient with very little reduction.
        </p>
        <p>
          If a potential saving is identified then
          <a href="https://www.amazon.co.uk/electricity-usage-monitor/s?k=electricity+usage+monitor"  target="_blank">appliance monitors</a>
          can be used to determine which fridge or freezer is most inefficient and would be economic to replace
          (please see the case study on Energy Sparks homepage
            <a href="https://energysparks.uk/case-studies"  target="_blank">here</a>
          ).
        </p>
        <%= @baseload_impact_html %>
      )
      ERB.new(text).result(binding)
    end

    private def introduction_text
      BenchmarkRefrigeration.intro
    end
  end
  #=======================================================================================
  class BenchmarkElectricityTarget < BenchmarkContentBase
    include BenchmarkingNoTextMixin

    private def introduction_text
      text = I18n.t('analytics.benchmarking.content.electricity_targets.introduction_text_html')
      ERB.new(text).result(binding)
    end
  end
    #=======================================================================================
    class BenchmarkGasTarget < BenchmarkContentBase
      include BenchmarkingNoTextMixin
  
      private def introduction_text
        text = I18n.t('analytics.benchmarking.content.gas_targets.introduction_text_html')
        ERB.new(text).result(binding)
      end
    end
  #=======================================================================================
  class BenchmarkContentBaseloadPerPupil < BenchmarkBaseloadBase
    include BenchmarkingNoTextMixin
    private def introduction_text
      text = I18n.t('analytics.benchmarking.content.baseload_per_pupil.introduction_text_html')
      text += I18n.t('analytics.benchmarking.caveat_text.es_exclude_storage_heaters_and_solar_pv')

      ERB.new(text).result(binding)
    end
  end

  #=======================================================================================
  class BenchmarkSeasonalBaseloadVariation < BenchmarkBaseloadBase
    include BenchmarkingNoTextMixin
    private def introduction_text
      text = I18n.t('analytics.benchmarking.content.seasonal_baseload_variation.introduction_text_html')
      text += I18n.t('analytics.benchmarking.caveat_text.es_exclude_storage_heaters_and_solar_pv')
      ERB.new(text).result(binding)
    end
  end

  #=======================================================================================
  class BenchmarkWeekdayBaseloadVariation < BenchmarkBaseloadBase
    include BenchmarkingNoTextMixin
    private def introduction_text
      text = I18n.t('analytics.benchmarking.content.weekday_baseload_variation.introduction_text_html')
      text += I18n.t('analytics.benchmarking.caveat_text.es_exclude_storage_heaters_and_solar_pv')
      ERB.new(text).result(binding)
    end
  end

  #=======================================================================================
  class BenchmarkContentPeakElectricityPerFloorArea < BenchmarkContentBase
    include BenchmarkingNoTextMixin
    private def introduction_text
      text = I18n.t('analytics.benchmarking.content.electricity_peak_kw_per_pupil.introduction_text_html')
      ERB.new(text).result(binding)      
    end
  end
    #=======================================================================================
    class BenchmarkContentSolarPVBenefit < BenchmarkContentBase
      include BenchmarkingNoTextMixin
      private def introduction_text
        text = I18n.t('analytics.benchmarking.content.solar_pv_benefit_estimate.introduction_text_html')
        ERB.new(text).result(binding)      
      end
    end
  #=======================================================================================
  class BenchmarkContentSummerHolidayBaseloadAnalysis < BenchmarkContentBase
    include BenchmarkingNoTextMixin
    private def introduction_text
      text = %q(
        <p>
          This analysis attempts to analyse whether a school
          has reduced its electricity consumption during the
          summer holidays.
        </p>
        <p>
          IIt&apos;s a useful way of
          determining the efficiency appliances which have been switched off.
          The school will need to know which appliances have been turned off
          in order for you to understand what contributed to the reduction.
        </p>
        <p>
          The most common reduction is due to some or all of kitchen fridges and
          freezers being turned off over the summer.
          Our <a href="https://energysparks.uk/case_studies/1/link" target ="_blank">case study</a>
          on this demonstrates that it is possible to get a short return on investment
          replacing old inefficient refrigeration with more efficient modern equipment.
          It is also good practice to empty and turn off refrigeration over the summer holidays
          - Energy Sparks can be configured to send an &apos;alert&apos; via email or text
          just before holidays to remind schools to do this.
        </p>
        <p>
          To further investigate the issue it is worth installing appliance monitors
          to establish accurately how inefficient equipment is, before making a purchasing decision.
          Domestic rather than commercial refrigeration generally offers much better value
          and efficiency.
        </p>
      )
      ERB.new(text).result(binding)
    end
    protected def table_introduction_text
      %q(
        <p>
          Large domestic A++ rated fridges
          and freezers typically use £40 of electricity per year each.
        </p>
        <p>
          This breakdown excludes electricity consumed by storage heaters and solar PV.
        </p>
       )
    end
  end
  #=======================================================================================
  class BenchmarkContentHeatingPerFloorArea < BenchmarkContentBase
    include BenchmarkingNoTextMixin
    private def introduction_text
      I18n.t('analytics.benchmarking.content.annual_heating_costs_per_floor_area.introduction_text_html')
    end
  end
  #=======================================================================================
  class BenchmarkContentChangeInAnnualHeatingConsumption < BenchmarkContentBase
    include BenchmarkingNoTextMixin

    def content(school_ids: nil, filter: nil, user_type: nil)
      content1 = super(school_ids: school_ids, filter: filter)
      content2 = temperature_adjusted_content(school_ids: school_ids, filter: filter)
      content1 + content2
    end

    private

    def temperature_adjusted_content(school_ids:, filter:)
      content_manager = Benchmarking::BenchmarkContentManager.new(@asof_date)
      db = @benchmark_manager.benchmark_database
      content_manager.content(db, :change_in_annual_heating_consumption_temperature_adjusted, filter: filter)
    end

    def introduction_text
      %q(
        <p>
          This benchmark shows the change in the gas and storage heater costs
          from last year to this year.
        </p>
        <p>
          Schools should aim to reduce their heating and hot water costs
          each year through better control of boilers and storage radiators;
          making sure they are switched off when unoccupied. Better management
          can typically reduce these costs by between 15% and 50%, at little
          or no cost to a school. Even something as simple as turning the thermostat
          down 1C can lead to a significant reduction in costs.
        </p>
        <p>
          Upgrading boilers, switching from gas based circulatory hot water systems
          to point of use electric hot water, and installing boiler optimum start control
          and weather compensation which require investment will reduce costs further.
        </p>
      ) + CAVEAT_TEXT[:covid_lockdown]
    end
  end
    #=======================================================================================
    class BenchmarkContentChangeInAnnualHeatingConsumptionTemperatureAdjusted  < BenchmarkContentBase
      include BenchmarkingNoTextMixin
  
      private def introduction_text
        %q(
          <p>
            The previous comparison is not adjusted for temperature changes between
            the two years.
          </p>

        )
      end
  
      protected def table_introduction_text
        %q(
          <p>
            This comparison is adjusted for temperature, so the previous year&apos;s
            temperature adjusted column is adjusted upwards if the previous year was
            milder than last year, and downwards if it is colder to provide a fairer
            comparison between the 2 years.

          </p>
        )
      end
    end
  #=======================================================================================
  class BenchmarkContentGasOutOfHoursUsage < BenchmarkContentBase
    include BenchmarkingNoTextMixin

    private def introduction_text
      I18n.t('analytics.benchmarking.content.annual_gas_out_of_hours_use.introduction_text_html')
    end
  end
  #=======================================================================================
  class BenchmarkContentStorageHeaterOutOfHoursUsage < BenchmarkContentBase
    include BenchmarkingNoTextMixin
    private def introduction_text
      %q(
        <p>
          Storage heaters consume electricity and store heat overnight when
          electricity is cheaper (assuming the school is on an &apos;economy 7&apos;
          type differential tariff) and releases the heat during the day.
        </p>
        <p>
          Ensuring heating is turned off over the weekend by installing a 7 day
          timer can provide very short paybacks - 16 weeks in this
          <a href="https://cdn-test.energysparks.uk/static-assets/Energy_Sparks_Case_Study_3_-_Stanton_Drew_Storage_Heaters-f124cfe069b2746ab175f139c09eee70fcb558d5604be86811c70fedd67a7a6d.pdf" target ="_blank">case study</a>.
          Turning off the heaters or turning them down as low as possible to avoid frost damage
          can save during holidays.
          We recommend you set a school policy for this. Energy Sparks
          can provide accurate estimates of the benefits of installing 7-day timers, or
          switching off during holidays if you drilldown to an individual school&apos;s analysis pages.
        </p>
        <p>
          You can get Energy Sparks to send you a reminder (an &apos;alert&apos;) just before holidays
          to turn your heating off.
        </p>
      )
    end
  end
  #=======================================================================================
  class BenchmarkContentThermostaticSensitivity < BenchmarkContentBase
    include BenchmarkingNoTextMixin
    private def introduction_text
      I18n.t('analytics.benchmarking.content.thermostat_sensitivity.introduction_text_html')
    end
  end
  #=======================================================================================
  class BenchmarkContentLengthOfHeatingSeasonDeprecated < BenchmarkContentBase
    include BenchmarkingNoTextMixin
    private def introduction_text
      %q(
        <p>
          Schools often forget to turn their heating off in warm weather,
          about 10% of schools leave their heating on all summer.
        </p>
        <p>
          The chart and table below show how many days the heating was
          left on in the last year and the potential benefit of switching
          the heating off in warmer weather. Schools should target reducing
          the length of the heating season to below 90 days.
        </p>
        <p>
          You can set up Energy Sparks email or text alerts which will notify
          you if the weather forecast for the coming week suggests you should
          turn off your heating.
        </p>
      )
    end
  end
    #=======================================================================================
    class BenchmarkContentHeatingInWarmWeather < BenchmarkContentBase
      include BenchmarkingNoTextMixin
      private def introduction_text
        I18n.t('analytics.benchmarking.content.heating_in_warm_weather.introduction_text_html')
      end
    end
  #=======================================================================================
  class BenchmarkContentThermostaticControl < BenchmarkContentBase
    include BenchmarkingNoTextMixin
    private def introduction_text
      I18n.t('analytics.benchmarking.content.thermostatic_control.introduction_text_html')
    end
  end
  #=======================================================================================
  class BenchmarkContentHotWaterEfficiency < BenchmarkContentBase
    include BenchmarkingNoTextMixin
    private def introduction_text
      I18n.t('analytics.benchmarking.content.hot_water_efficiency.introduction_text_html')
    end
  end
  #=======================================================================================
  # 2 sets of charts, tables on one page
  class BenchmarkHeatingComingOnTooEarly < BenchmarkContentBase
    include BenchmarkingNoTextMixin
    private def introduction_text
      I18n.t('analytics.benchmarking.content.heating_coming_on_too_early.introduction_text_html')
    end

    def content(school_ids: nil, filter: nil, user_type: nil)
      content1 = super(school_ids: school_ids, filter: filter)
      content2 = optimum_start_content(school_ids: school_ids, filter: filter)
      content1 + content2
    end

    private

    def optimum_start_content(school_ids:, filter:)
      content_manager = Benchmarking::BenchmarkContentManager.new(@asof_date)
      db = @benchmark_manager.benchmark_database
      content_manager.content(db, :optimum_start_analysis, filter: filter)
    end
  end

  #=======================================================================================
  class BenchmarkContentEnergyPerFloorArea < BenchmarkContentBase
    # config key annual_energy_costs_per_floor_area
    include BenchmarkingNoTextMixin

    private def introduction_text
      text = '<p>'
      text += I18n.t('analytics.benchmarking.content.annual_energy_costs_per_floor_area.introduction_text_html')
      text += I18n.t('analytics.benchmarking.caveat_text.es_per_pupil_v_per_floor_area_useful_html')
      text += '</p>'
      ERB.new(text).result(binding)
    end
  end
  #=======================================================================================
  class BenchmarkContentChangeInEnergyUseSinceJoined < BenchmarkContentBase
    include BenchmarkingNoTextMixin

    private def introduction_text
      text = I18n.t('analytics.benchmarking.content.change_in_energy_use_since_joined_energy_sparks.introduction_text_html')
      text += I18n.t('analytics.benchmarking.caveat_text.covid_lockdown')

      ERB.new(text).result(binding)
    end
    protected def chart_interpretation_text
      text = I18n.t('analytics.benchmarking.content.change_in_energy_use_since_joined_energy_sparks.chart_interpretation_text_html')
      ERB.new(text).result(binding)
    end

    def content(school_ids: nil, filter: nil, user_type: nil)
      content1 = super(school_ids: school_ids, filter: filter)
      content2 = full_energy_change_breakdown(school_ids: school_ids, filter: filter)
      content1 + content2
    end

    private

    def full_energy_change_breakdown(school_ids:, filter:)
      content_manager = Benchmarking::BenchmarkContentManager.new(@asof_date)
      db = @benchmark_manager.benchmark_database
      content_manager.content(db, :change_in_energy_use_since_joined_energy_sparks_full_data, filter: filter)
    end
  end
  #=======================================================================================
  class BenchmarkContentChangeInEnergyUseSinceJoinedFullData < BenchmarkContentBase
    include BenchmarkingNoTextMixin

    private def introduction_text
      text = %q(
        <p>
          This table provides a more detailed breakdown of the data provided in the chart
          and table above. <%= CAVEAT_TEXT[:covid_lockdown] %>
        </p>
      )
      ERB.new(text).result(binding)
    end
  end
  #=======================================================================================
  # this benachmark generates 2 charts and 1 table
  class BenchmarkContentChangeInCO2SinceLastYear < BenchmarkContentBase
    include BenchmarkingNoTextMixin

    private def introduction_text
      text = %q(
        <p>
          This benchmark compares the change in annual CO2 emissions between the last two years.
          All CO2 is expressed in kg (kilograms).
        </p>
        <%= CAVEAT_TEXT[:covid_lockdown] %>
      )
      ERB.new(text).result(binding)
    end

    def content(school_ids: nil, filter: nil, user_type: nil)
      content1 = super(school_ids: school_ids, filter: filter)
      content2 = full_co2_breakdown(school_ids: school_ids, filter: filter)
      content1 + content2
    end

    private

    def full_co2_breakdown(school_ids:, filter:)
      content_manager = Benchmarking::BenchmarkContentManager.new(@asof_date)
      db = @benchmark_manager.benchmark_database
      content_manager.content(db, :change_in_co2_emissions_since_last_year_full_table, filter: filter)
    end
  end
  #=======================================================================================
  class BenchmarkContentChangeInCO2SinceLastYearFullData  < BenchmarkContentBase
    include BenchmarkingNoTextMixin

    private def introduction_text
      %q(
        <p>
          This chart provides a breakdown of the change in CO2 emissions
          between electricity, gas and solar PV, and allows you to see which
          has increased and decreased.
        </p>
        <p>
          Generally an increase in solar PV production between last year and the year
          before, would lead to a reduction in CO2 emissions in the chart below,
          as the more electricity is produced by a school&apos;s solar PV panels
          the less CO2 a school emits overall.
        </p>
      )
    end

    protected def table_introduction_text
      %q(
        <p>
          The solar PV CO2 columns in the table below are emissions the school saves from consuming
          electricity produced by its solar panels, and the benefit to the national grid from exporting
          surplus electricity. It&apos;s negative because it reduces the school&apos;s overall carbon emissions.
          The solar CO2 is calculated as the output of the panels times the carbon intensity of the
          national grid at the time of the output (half hour periods). So for example a reduction
          in CO2 offset by the school&apos;s panels from one year to the next doesn&apos;t necessarily
          imply a loss of performance of the panels but potentially a decarbonisation of the grid.
          As the grid decarbonises solar PV will gradually have a lower impact on reducing a
          school&apos;s carbon emissions, but conversely the school&apos;s carbon emissions
          from grid consumption will be lower.
        </p>
      )
    end
  end

  #=======================================================================================
  # shared wording save some translation costs
  class BenchmarkAnnualChangeBase < BenchmarkContentBase
    def table_introduction(fuel_types, direction = 'use')
      text = %q(
        <p>
          This table compares <%= fuel_types %> <%= direction %> between this year to date
          (defined as ‘last year’ in the table below) and the corresponding period
          from the year before (defined as ‘previous year’).
        </p>
      )

      ERB.new(text).result(binding)
    end

    def varying_directions(list, in_list = true)
      text = %q(
        <%= in_list ? 't' : 'T'%>he kWh, CO2, £ values can move in opposite directions and by
        different percentages because the following may vary between
        the two years:
        <%= to_bulleted_list(list) %>
      )

      ERB.new(text).result(binding)
    end

    def electric_and_gas_mix
      %q( the mix of electricity and gas )
    end

    def carbon_intensity
      %q( the carbon intensity of the electricity grid )
    end

    def day_night_tariffs
      %q(
        the proportion of electricity consumed between night and day for schools
        with differential tariffs (economy 7)
      )
    end

    def only_in_previous_column
      %q(
        data only appears in the 'previous year' column if two years
        of data are available for the school
      )
    end

    def to_bulleted_list(list)
      text = %q(
        <ul>
          <%= list.map { |li| "<li>#{li}</li>" }.join('') %>
        </ul>
      )

      ERB.new(text).result(binding)
    end

    def cost_solar_pv
      %q(
        the cost column for schools with solar PV only represents the cost of consumption
        i.e. mains plus electricity consumed from the solar panels using a long term economic value.
        It doesn't use the electricity or solar PV tariffs for the school
      )
    end

    def solar_pv_electric_calc
      %q(
        the electricity consumption for schools with solar PV is the total
        of electricity consumed from the national grid plus electricity
        consumed from the solar PV (self-consumption)
        but excludes any excess solar PV exported to the grid
      )
    end

    def sheffield_estimate
      %q(
        self-consumption is estimated where we don't have metered solar PV,
        and so the overall electricity consumption will also not be 100% accurate,
        but will be a ‘good’ estimate of the year on year change
      )
    end

    def storage_heater_comparison
      %q(
        The electricity consumption also excludes storage heaters
        which are compared in a separate comparison
      )
    end

    def colder
      %q(
        <p>
          The &apos;adjusted&apos; columns are adjusted for difference in
          temperature between the two years. So for example, if the previous year was colder
          than last year, then the adjusted previous year gas consumption
          in kWh is adjusted to last year&apos;s temperatures and would be smaller than
          the unadjusted previous year value. The adjusted percent change is a better
          indicator of the work a school might have done to reduce its energy consumption as
          it&apos;s not dependent on temperature differences between the two years.
        </p>
      )
    end
  end 
  #=======================================================================================
  class BenchmarkChangeInEnergySinceLastYear < BenchmarkAnnualChangeBase
    include BenchmarkingNoTextMixin

    private def introduction_text
      text = I18n.t('analytics.benchmarking.content.change_in_energy_since_last_year.introduction_text_html')
      text += I18n.t('analytics.benchmarking.caveat_text.covid_lockdown')
      ERB.new(text).result(binding)
    end

    def content(school_ids: nil, filter: nil, user_type: nil)
      content1 = super(school_ids: school_ids, filter: filter)
      # content2 = full_co2_breakdown(school_ids: school_ids, filter: filter)
      # content3 = full_energy_breakdown(school_ids: school_ids, filter: filter)
      content1 # + content2 + content3
    end

    private

    def full_co2_breakdown(school_ids:, filter:)
      content_manager = Benchmarking::BenchmarkContentManager.new(@asof_date)
      db = @benchmark_manager.benchmark_database
      content_manager.content(db, :change_in_co2_emissions_since_last_year_full_table, filter: filter)
    end

    def full_energy_breakdown(school_ids:, filter:)
      content_manager = Benchmarking::BenchmarkContentManager.new(@asof_date)
      db = @benchmark_manager.benchmark_database
      content_manager.content(db, :change_in_energy_since_last_year_full_table, filter: filter)
    end
  end
  #=======================================================================================
  class BenchmarkChangeInElectricitySinceLastYear < BenchmarkAnnualChangeBase
    include BenchmarkingNoTextMixin

    # some text duplication with the BenchmarkChangeInEnergySinceLastYear class
    private def introduction_text
      text = I18n.t('analytics.benchmarking.content.change_in_electricity_since_last_year.introduction_text_html')
      text += I18n.t('analytics.benchmarking.caveat_text.covid_lockdown')
      ERB.new(text).result(binding)
    end
  end
  #=======================================================================================
  class BenchmarkChangeInGasSinceLastYear < BenchmarkAnnualChangeBase
    include BenchmarkingNoTextMixin

    private def introduction_text
      text = I18n.t('analytics.benchmarking.content.change_in_gas_since_last_year.introduction_text_html')
      text += I18n.t('analytics.benchmarking.caveat_text.covid_lockdown')

      ERB.new(text).result(binding)
    end
  end
  #=======================================================================================
  class BenchmarkChangeInStorageHeatersSinceLastYear < BenchmarkAnnualChangeBase
    include BenchmarkingNoTextMixin

    private def introduction_text
      text = I18n.t('analytics.benchmarking.content.change_in_storage_heaters_since_last_year.introduction_text_html')
      text += I18n.t('analytics.benchmarking.caveat_text.covid_lockdown')
      ERB.new(text).result(binding)
    end
  end
  #=======================================================================================
  class BenchmarkChangeInSolarPVSinceLastYear < BenchmarkAnnualChangeBase
    include BenchmarkingNoTextMixin

    private def introduction_text
      text = I18n.t('analytics.benchmarking.content.change_in_solar_pv_since_last_year.introduction_text_html')
      ERB.new(text).result(binding)
    end
  end
  #=======================================================================================
  class BenchmarkOptimumStartAnalysis  < BenchmarkContentBase
    include BenchmarkingNoTextMixin

    private def introduction_text
      %q(
        <p>
          This experimental analysis attempts to help determine whether
          a school&apos;s optimum start control is working by looking at
          the times the boiler has started over the last year.
        </p>
      )
    end

    protected def table_introduction_text
      %q(
        <p>
          The &apos;standard deviation&apos; column shows over how many hours
          the starting time has varied over the last year. If this is more than
          an hour or so, it might indicate the optimum start control is working,
          or it could be that someone has made lots of adjustments to the boiler
          start time during the year.
        </p>
        <p>
          The &apos;Regression model optimum start R2&apos; indicates how well
          correlated with outside temperature the start time of the boiler was.
          The closer to 1.0, the more correlated it was and therefore the
          more likely the optimum start control is working well.
        </p>
      )
    end

    protected def caveat_text
      %q(
        <p>
          However, these calculations are experimental and might not provide
          good indicators of how well the optimum start is working for all schools.
          Drilling down to look at the data for an individual school should provide
          a better indication.
        <p>
      )
    end
  end
  #=======================================================================================
  class BenchmarkContentElectricityMeterConsolidation < BenchmarkContentBase
    include BenchmarkingNoTextMixin
    private def introduction_text
      %q(
        <p>
          Electricity meters can have quite high standing charges, between &pound;500
          and &pound;5,000 per year. If a school has several electricity meters
          it might be worth consolidating them i.e. getting your local electricity
          network provider or energy company to reduce the number of meters in a
          school to reduce annual standing order costs, this consolidation
          often costs about &pound;1,000.
        </p>
        <p>
          You need to consider how far apart the meters are, if for example they
          are in the same room or cupboard the change could cost you very little.
          The choice can also be determined by whether you have storage heaters,
          historically it would have been cheaper to have them on a separate meter,
          but with the advent of smart and advanced meters 10 years ago this is
          less necessary as your energy supplier can read you meters half hourly
          and can charge the appropriate lower cost for your overnight usage.
        </p>
        <p>
          This is a simple low cost change a school can make, the chart and table below
          attempt to estimate the potential saving based on some indicative standing charges
          for your area; you will need to look at your bills to get a more accurate
          estimate.
        </p>
      )
    end

    def table_introduction_text
      %q(
        <p>
          Opportunities to save money through consolidation will only
          exist if a school has multiple electricity meters.
        </p>
      )
    end
  end
  #=======================================================================================
  class BenchmarkContentGasMeterConsolidation < BenchmarkContentBase
    include BenchmarkingNoTextMixin
    private def introduction_text
      %q(
        <p>
          Gas meters can have quite high standing charges, between &pound;500
          and &pound;5,000 per year. If a school has a number of gas meters
          it might be worth consolidating them i.e. getting your local gas
          network provider or energy company to reduce the number of meters in a
          school to reduce annual standing order costs, this consolidation
          often costs about &pound;1,000 but can provide guaranteed annual savings.
        </p>
      )
    end

    def table_introduction_text
      %q(
        <p>
          Opportunities to save money through consolidation will only
          exist if a school has multiple gas meters.
        </p>
      )
    end
  end
  #=======================================================================================
  class BenchmarkContentDifferentialTariffOpportunity < BenchmarkContentBase
    include BenchmarkingNoTextMixin
    private def introduction_text
      %q(
        <p>
          Electricity is generally charged at a flat rate, for example 30p/kWh
          whatever the time of day. Your energy company&apos;s costs however
          vary significantly depending on supply and demand at different times
          of day, from perhaps 7p/kWh overnight to 45p/kWh at peak times.
          Electricity companies generally offer differential tariff&apos;s
          (economy 7) which have lower overnight costs (typically 30p/kWh) and
          slightly higher daytime costs (32p/kWh) to users who have high overnight
          consumption to share the benefit of cheaper overnight wholesale costs.
        </p>
        <p>
          Typically, this should benefit schools with storage heaters, however
          many schools with storage heaters are on a single flat tariff and fail
          to gain from lower overnight prices.
        </p>
        <p>
          Many schools don&apos;t have their differential tariffs configured on
          Energy Sparks, please get in contact if you think this is the case at
          your school, so we can provide better analysis for your school.
        </p>
        <p>
          The chart and table below estimate the potential benefit of switching
          to or from a differential tariff.
        </p>
      )
    end
  end
  #=======================================================================================
  module BenchmarkPeriodChangeBaseElectricityMixIn
    def current_variable;     :current_pupils   end
    def previous_variable;    :previous_pupils  end
    def variable_type;        :pupils           end
    def has_changed_variable; :pupils_changed   end

    def change_variable_description
      'number of pupils'
    end

    def has_possessive
      'have'
    end

    def fuel_type_description
      'electricity'
    end
  end

  module BenchmarkPeriodChangeBaseGasMixIn
    def current_variable;     :current_floor_area   end
    def previous_variable;    :previous_floor_area  end
    def variable_type;        :m2                   end
    def has_changed_variable; :floor_area_changed   end

    def change_variable_description
      'floor area'
    end

    def has_possessive
      'has'
    end

    def fuel_type_description
      'gas'
    end
  end

  class BenchmarkPeriodChangeBase < BenchmarkContentBase
    include BenchmarkingNoTextMixin

    def content(school_ids: nil, filter: nil, user_type: nil)
      @rate_changed_in_period = calculate_rate_changed_in_period(school_ids, filter, user_type)
      super(school_ids: school_ids, filter: filter)
    end

    private

    def footnote(school_ids, filter, user_type)
      raw_data = benchmark_manager.run_table_including_aggregate_columns(asof_date, page_name, school_ids, nil, filter, :raw, user_type)
      rows = raw_data.drop(1) # drop header

      return '' if rows.empty?

      floor_area_or_pupils_change_rows = changed_rows(rows, has_changed_variable)

      infinite_increase_school_names = school_names_by_calculation_issue(rows, :percent_changed, +Float::INFINITY)
      infinite_decrease_school_names = school_names_by_calculation_issue(rows, :percent_changed, -Float::INFINITY)

      changed = !floor_area_or_pupils_change_rows.empty? ||
                !infinite_increase_school_names.empty? ||
                !infinite_decrease_school_names.empty? ||
                @rate_changed_in_period


      text = %(
        <% if changed %>
          <p> 
            Notes:
            <ul>
              <% if !floor_area_or_pupils_change_rows.empty? %>
                <li>
                  (*1) the comparison has been adjusted because the <%= change_variable_description %>
                      <%= has_possessive %> changed between the two <%= period_types %> for
                      <%= floor_area_or_pupils_change_rows.map { |row| change_sentence(row) }.join(', and ') %>.
                </li>
              <% end %>
              <% if !infinite_increase_school_names.empty? %>
                <li>
                  (*2) schools where percentage change
                      is +Infinity is caused by the <%= fuel_type_description %> consumption
                      in the previous <%= period_type %> being more than zero
                      but in the current <%= period_type %> zero
                </li>
              <% end %>
              <% if !infinite_decrease_school_names.empty? %>
                <li>
                  (*3) schools where percentage change
                      is -Infinity is caused by the <%= fuel_type_description %> consumption
                      in the current <%= period_type %> being zero
                      but in the previous <%= period_type %> it was more than zero
                </li>
              <% end %>
              <% if @rate_changed_in_period %>
                <li>
                  (*6) schools where the economic tariff has changed between the two periods,
                       this is not reflected in the &apos;<%= BenchmarkManager.ch(:change_£current) %>&apos;
                       column as it is calculated using the most recent tariff.
                </li>
              <% end %>
            </ul>
          </p>
        <% end %>
      )
      ERB.new(text).result(binding)
    end

    def calculate_rate_changed_in_period(school_ids, filter, user_type)
      col_index = column_headings(school_ids, filter, user_type).index(:tariff_changed_period)
      return false if col_index.nil?

      data = raw_data(school_ids, filter, user_type)
      return false if data.nil? || data.empty?

      rate_changed_in_periods = data.map { |row| row[col_index] }

      rate_changed_in_periods.any?
    end

    def list_of_school_names_text(school_name_list)
      if school_name_list.length <= 2
        school_name_list.join(' and ')
      else
        (school_name_list.first school_name_list.size - 1).join(' ,') + ' and ' + school_name_list.last
      end 
    end

    def school_names_by_calculation_issue(rows, column_id, value)
      rows.select { |row| row[table_column_index(column_id)] == value }
    end

    def school_names(rows)
      rows.map { |row| remove_references(row[table_column_index(:school_name)]) }
    end

    # reverses def referenced(name, changed, percent) in benchmark_manager.rb
    def remove_references(school_name)
      puts "Before #{school_name} After #{school_name.gsub(/\(\*[[:blank:]]([[:digit:]]+,*)+\)/, '')}"
      school_name.gsub(/\(\*[[:blank:]]([[:digit:]]+,*)+\)/, '')
    end

    def changed_variable_column_index(change_variable)
      table_column_index(change_variable)
    end

    def changed?(row, change_variable)
      row[changed_variable_column_index(change_variable)] == true
    end

    def changed_rows(rows, change_variable)
      rows.select { |row| changed?(row, change_variable) }
    end

    def no_changes?(rows,  change_variable)
      rows.all?{ |row| !changed?(row, change_variable) }
    end

    def change_sentence(row)
      school_name = remove_references(row[table_column_index(:school_name)])
      current     = row[table_column_index(current_variable) ].round(0)
      previous    = row[table_column_index(previous_variable)].round(0)

      text = %(
        <%= school_name %>
        from <%= FormatEnergyUnit.format(variable_type, current, :html) %>
        to <%= FormatEnergyUnit.format(variable_type, previous, :html) %>
      )
      ERB.new(text).result(binding)
    end
  end
  #=======================================================================================
  class BenchmarkContentChangeInElectricityConsumptionSinceLastSchoolWeek < BenchmarkPeriodChangeBase
    include BenchmarkPeriodChangeBaseElectricityMixIn

    def period_type
      'school week'
    end

    def period_types
      "#{period_type}s" # pluralize
    end

    private def introduction_text
      text = I18n.t('analytics.benchmarking.content.change_in_electricity_consumption_recent_school_weeks.introduction_text_html')
      text += I18n.t('analytics.benchmarking.caveat_text.comparison_with_previous_period_infinite')
      ERB.new(text).result(binding)
    end
  end
  #=======================================================================================
  class BenchmarkHolidaysChangeBase < BenchmarkPeriodChangeBase
    def period_type
      'holiday'
    end

    def period_types
      "#{period_type}s" # pluralize
    end
  end
  #=======================================================================================
  class BenchmarkContentChangeInElectricityBetweenLast2Holidays < BenchmarkHolidaysChangeBase
    include BenchmarkPeriodChangeBaseElectricityMixIn
    private def introduction_text
      text = I18n.t('analytics.benchmarking.content.change_in_electricity_holiday_consumption_previous_holiday.introduction_text_html')
      text += I18n.t('analytics.benchmarking.caveat_text.comparison_with_previous_period_infinite')
      ERB.new(text).result(binding)
    end
  end
  #=======================================================================================
  class BenchmarkContentChangeInElectricityBetween2HolidaysYearApart < BenchmarkHolidaysChangeBase
    include BenchmarkPeriodChangeBaseElectricityMixIn
    private def introduction_text
      text = I18n.t('analytics.benchmarking.content.change_in_electricity_holiday_consumption_previous_years_holiday.introduction_text_html')
      text += I18n.t('analytics.benchmarking.caveat_text.comparison_with_previous_period_infinite')
      ERB.new(text).result(binding)
    end
  end
  #=======================================================================================
  class BenchmarkContentChangeInGasConsumptionSinceLastSchoolWeek < BenchmarkHolidaysChangeBase
    include BenchmarkPeriodChangeBaseGasMixIn

    private def introduction_text
      text = I18n.t('analytics.benchmarking.content.change_in_gas_consumption_recent_school_weeks.introduction_text_html')
      text += I18n.t('analytics.benchmarking.caveat_text.comparison_with_previous_period_infinite')
      ERB.new(text).result(binding)
    end
  end
  #=======================================================================================
  class BenchmarkContentChangeInGasBetweenLast2Holidays < BenchmarkHolidaysChangeBase
    include BenchmarkPeriodChangeBaseGasMixIn

    private def introduction_text
      text = I18n.t('analytics.benchmarking.content.change_in_gas_holiday_consumption_previous_holiday.introduction_text_html')
      text +=  I18n.t('analytics.benchmarking.caveat_text.comparison_with_previous_period_infinite')
      ERB.new(text).result(binding)
    end
  end
  #=======================================================================================
  class BenchmarkContentChangeInGasBetween2HolidaysYearApart < BenchmarkHolidaysChangeBase
    include BenchmarkPeriodChangeBaseGasMixIn

    private def introduction_text
      text = %q(
        <p>
          This comparison shows the change in consumption during the most recent holiday, and
          the same holiday a year ago. Schools should be looking to reduce holiday usage
          by switching heating and hot water off over holidays when it is often unnecessary.
          A significant  increase from year to year suggests a school is not managing to reduce consumption,
          which would help mitigate some of the impacts of climate change. You can setup an Energy Sparks &apos;alert&apos; to
          send you an email or text message just before a holiday to remind you to
          turn the heating or hot water off.
        </p>
        <%= CAVEAT_TEXT[:temperature_compensation] %>
        <%= CAVEAT_TEXT[:comparison_with_previous_period_infinite] %>
      )
      ERB.new(text).result(binding)
    end
  end
  #=======================================================================================
  class BenchmarkHeatingHotWaterOnDuringHolidayBase < BenchmarkContentBase
    include BenchmarkingNoTextMixin
    private def introduction_text
      text = %q(
        <p>
          This chart shows the projected <%= fuel %> costs for the current holiday.
          No comparative data will be shown once the holiday is over. The projection
          calculation is based on the consumption patterns during the holiday so far.
        </p>
      )
      ERB.new(text).result(binding)
    end
  end

  class BenchmarkElectricityOnDuringHoliday < BenchmarkContentBase
    include BenchmarkingNoTextMixin
    private def introduction_text
      text = I18n.t('analytics.benchmarking.content.electricity_consumption_during_holiday.introduction_text_html')
      text += I18n.t('analytics.benchmarking.caveat_text.es_exclude_storage_heaters_and_solar_pv_data_html')
      ERB.new(text).result(binding)
    end
  end

  class BenchmarkGasHeatingHotWaterOnDuringHoliday < BenchmarkHeatingHotWaterOnDuringHolidayBase
    include BenchmarkingNoTextMixin
    def introduction_text
      I18n.t('analytics.benchmarking.content.gas_consumption_during_holiday.introduction_text_html')
    end
    def fuel; 'gas' end
  end

  class BenchmarkStorageHeatersOnDuringHoliday < BenchmarkHeatingHotWaterOnDuringHolidayBase
    include BenchmarkingNoTextMixin
    def introduction_text
      I18n.t('analytics.benchmarking.content.storage_heater_consumption_during_holiday.introduction_text_html')
    end
    def fuel; 'storage heeaters' end
  end
  #=======================================================================================
  class BenchmarkEnergyConsumptionInUpcomingHolidayLastYear < BenchmarkContentBase
    include BenchmarkingNoTextMixin
    private def introduction_text
      text = I18n.t('analytics.benchmarking.content.holiday_usage_last_year.introduction_text_html')
      text += I18n.t('analytics.benchmarking.caveat_text.covid_lockdown')
      ERB.new(text).result(binding)
    end
  end
#=======================================================================================
  class BenchmarkChangeAdhocComparison < BenchmarkContentBase
    include BenchmarkingNoTextMixin
    private def introduction_text
      text = I18n.t('analytics.benchmarking.content.layer_up_powerdown_day_november_2022.introduction_text_html')
      ERB.new(text).result(binding)
    end

    # combine content of 4 tables: energy, electricity, gas, storage heaters
    def content(school_ids: nil, filter: nil, user_type: nil)
      content1 = super(school_ids: school_ids, filter: filter)
      content2 = electricity_content(school_ids: school_ids, filter: filter)
      content3 = gas_content(school_ids: school_ids, filter: filter)
      content4 = storage_heater_content(school_ids: school_ids, filter: filter)
      content1 + content2 + content3  + content4
    end

    private

    def electricity_content(school_ids:, filter:)
      extra_content(:layer_up_powerdown_day_november_2022_electricity_table, filter: filter)
    end

    def gas_content(school_ids:, filter:)
      extra_content(:layer_up_powerdown_day_november_2022_gas_table, filter: filter)
    end

    def storage_heater_content(school_ids:, filter:)
      extra_content(:layer_up_powerdown_day_november_2022_storage_heater_table, filter: filter)
    end
    
    def extra_content(type, filter:)
      content_manager = Benchmarking::BenchmarkContentManager.new(@asof_date)
      db = @benchmark_manager.benchmark_database
      content_manager.content(db, type, filter: filter)
    end
  end

  class BenchmarkChangeAdhocComparisonElectricityTable < BenchmarkContentBase
    include BenchmarkingNoTextMixin
  end

  class BenchmarkChangeAdhocComparisonGasTable < BenchmarkContentBase
    include BenchmarkingNoTextMixin
    private def introduction_text
      'The change columns are calculated using temperature adjusted values:'
    end
  end

  class BenchmarkChangeAdhocComparisonStorageHeaterTable < BenchmarkChangeAdhocComparisonGasTable
    include BenchmarkingNoTextMixin
  end

  #=======================================================================================
  class BenchmarkAutumn2022Comparison < BenchmarkChangeAdhocComparison
    def electricity_content(school_ids:, filter:)
      extra_content(:autumn_term_2021_2022_electricity_table, filter: filter)
    end
  
    def gas_content(school_ids:, filter:)
      extra_content(:autumn_term_2021_2022_gas_table, filter: filter)
    end
  
    def storage_heater_content(school_ids:, filter:)
      extra_content(:autumn_term_2021_2022_storage_heater_table, filter: filter)
    end
  end

  class BenchmarkAutumn2022ElectricityTable < BenchmarkContentBase
    include BenchmarkingNoTextMixin
  end

  class BenchmarkAutumn2022GasTable < BenchmarkContentBase
    include BenchmarkingNoTextMixin

    private def introduction_text
      'The change columns are calculated using temperature adjusted values:'
    end
  end

  class BenchmarkAutumn2022StorageHeaterTable < BenchmarkChangeAdhocComparisonGasTable
    include BenchmarkingNoTextMixin
  end

  #=======================================================================================
  class BenchmarkSeptNov2022Comparison < BenchmarkChangeAdhocComparison

    def electricity_content(school_ids:, filter:)
      extra_content(:sept_nov_2021_2022_electricity_table, filter: filter)
    end
  
    def gas_content(school_ids:, filter:)
      extra_content(:sept_nov_2021_2022_gas_table, filter: filter)
    end
  
    def storage_heater_content(school_ids:, filter:)
      extra_content(:sept_nov_2021_2022_storage_heater_table, filter: filter)
    end
  end

  class BenchmarkSeptNov2022ElectricityTable < BenchmarkContentBase
    include BenchmarkingNoTextMixin
  end

  class BenchmarkSeptNov2022GasTable < BenchmarkContentBase
    include BenchmarkingNoTextMixin

    private def introduction_text
      'The change columns are calculated using temperature adjusted values:'
    end
  end

  class BenchmarkSeptNov2022StorageHeaterTable < BenchmarkChangeAdhocComparisonGasTable
    include BenchmarkingNoTextMixin
  end

end
