require_relative './alert_analysis_base.rb'
require_relative '../energy_sparks_exceptions.rb'
# General base class for 6 alerts:
# - School week comparison: gas + electric
# - Previous holiday week comparison: gas + electric
# - Same holiday week last year comparison: gas + electric
# Generally try to recalculate periods everytime, just in case asof_date is varied in testing process
## school week, previous holiday, last year holiday comparison
#
# Relevance and enough data:
# - the alert is relevant only up to 3 weeks after the current period e.g. become irrelevant 3 weeks after a holiday
# - or for school weeks 3 weeks into a holiday
# - enough data - need enough meter data for both periods, but this can be less (6 days) than the whole period
# - so that the alert can for example signal the heating is on, if running in the middle of a holiday
# - for gas data, its also subject to enough model data for the model calculation to run
# Example as of dates for testing:
#   Whiteways: 4 Oct 2015: start of electricity, 6 Apr 2014 start of gas
#   Date.new(2015, 10, 6): all gas, but only school week relevant, no electricity
#   Date.new(2014, 7, 5): no electricity, no gas because of shortage of model data
#   Date.new(2014, 12, 1): no electricity, but should be enough model data to do school week, previous holiday, but not previous year holiday
#   Date.new(2018, 1, 1): all should be relevant
#   Date.new(2019, 3, 30): holiday alerts not relevant because towards end of term
#   Date.new(2019, 4, 3): holiday alerts not relvant because not far enough into holiday
#   Date.new(2019, 4, 10): all alerts should be relevant as far enough into holiday for enough data
#   Date.new(2019, 4, 24): all alerts should be relevant as within 3 weeks of end of holiday

class AlertPeriodComparisonBase < AlertAnalysisBase
  DAYS_ALERT_RELEVANT_AFTER_CURRENT_PERIOD = 3 * 7 # alert relevant for up to 3 weeks after period (holiday)
  # for the purposes to a 'relevant' alert we need a minimum of 6 days
  # period data, this ensures at least 1 weekend day is present for
  # the averaging process
  MINIMUM_DAYS_DATA_FOR_RELEVANT_PERIOD = 6
  MINIMUM_DIFFERENCE_FOR_NON_10_RATING_£ = 10.0
  attr_reader :difference_kwh, :difference_£, :difference_percent
  attr_reader :current_period_kwh, :current_period_£, :current_period_start_date, :current_period_end_date
  attr_reader :previous_period_kwh, :previous_period_£, :previous_period_start_date, :previous_period_end_date
  attr_reader :days_in_current_period, :days_in_previous_period
  attr_reader :name_of_current_period, :name_of_previous_period
  attr_reader :current_period_average_kwh, :previous_period_average_kwh
  attr_reader :current_holiday_temperatures, :current_holiday_average_temperature
  attr_reader :previous_holiday_temperatures, :previous_holiday_average_temperature
  attr_reader :current_period_kwhs, :previous_period_kwhs_unadjusted, :previous_period_average_kwh_unadjusted
  attr_reader :current_period_weekly_kwh, :current_period_weekly_£, :previous_period_weekly_kwh, :previous_period_weekly_£
  attr_reader :change_in_weekly_kwh, :change_in_weekly_£
  attr_reader :change_in_weekly_percent

  def self.dynamic_template_variables(fuel_type)
    {
      difference_kwh:     { description: 'Difference in kwh between last 2 periods', units:  { kwh: fuel_type } },
      difference_£:       { description: 'Difference in £ between last 2 periods',   units:  :£  },
      difference_percent: { description: 'Difference in % between last 2 periods',   units:  :percent  },

      current_period_kwh:        { description: 'Current period kwh',                 units:  { kwh: fuel_type } },
      current_period_£:          { description: 'Current period £',                   units:  :£  },
      current_period_start_date: { description: 'Current period start date',          units:  :date  },
      current_period_end_date:   { description: 'Current period end date',            units:  :date  },
      days_in_current_period:    { description: 'No. of days in current period',      units: Integer },
      name_of_current_period:    { description: 'name of current period e.g. Easter', units: String },

      previous_period_kwh:        { description: 'Previous period kwh',             units:  { kwh: fuel_type } },
      previous_period_£:          { description: 'Previous period £',               units:  :£  },
      previous_period_start_date: { description: 'Previous period start date',      units:  :date  },
      previous_period_end_date:   { description: 'Previous period end date',        units:  :date  },
      days_in_previous_period:    { description: 'No. of days in previous period',  units: Integer },
      name_of_previous_period:    { description: 'name of pervious period',         units: String },

      current_period_average_kwh:  { description: 'Current period average daily kwh', units:  { kwh: fuel_type } },
      previous_period_average_kwh: { description: 'Previous period average daily',    units:  { kwh: fuel_type } },

      current_holiday_temperatures:     { description: 'Current period temperatures', units:  String  },
      previous_holiday_temperatures:    { description: 'Previous period temperatures', units:  String  },

      current_holiday_average_temperature:  { description: 'Current periods average temperature',  units:  :temperature },
      previous_holiday_average_temperature: { description: 'Previous periods average temperature', units:  :temperature },

      previous_period_average_kwh_unadjusted: { description: 'Previous period average unadjusted kwh',  units:  { kwh: fuel_type } },
      current_period_kwhs:                    { description: 'Current period kwh values', units:  String  },
      previous_period_kwhs_unadjusted:        { description: 'Previous period kwh values', units:  String  },

      current_period_weekly_kwh:  { description: 'Current period normalised average weekly kwh',   units:  { kwh: fuel_type } },
      current_period_weekly_£:    { description: 'Current period normalised average weekly £',     units:  :£  },
      previous_period_weekly_kwh: { description: 'Previous period normalised average weekly kwh',  units:  { kwh: fuel_type } },
      previous_period_weekly_£:   { description: 'Previous period normalised average weekly £',    units:  :£  },
      change_in_weekly_kwh:       { description: 'Change in normalised average weekly kwh',        units:  { kwh: fuel_type } },
      change_in_weekly_£:         { description: 'Change in normalised average weekly £',          units:  :£  },
      change_in_weekly_percent:   { description: 'Difference in weekly % between last 2 periods',  units:  :percent  },

      comparison_chart: { description: 'Relevant comparison chart', units: :chart }
    }
  end

  protected def comparison_chart
    raise EnergySparksAbstractBaseClass, "Error: comparison_chart method not implemented for #{self.class.name}"
  end

  def aggregate_meter
    fuel_type == :electricity ? @school.aggregated_electricity_meters : @school.aggregated_heat_meters
  end

  def timescale; 'Error- should be overridden' end

  def relevance; @relevance end # overridden in calculate

  def maximum_alert_date; aggregate_meter.amr_data.end_date end

  def calculate(asof_date)
    configure_models(asof_date)
    current_period, previous_period = last_two_periods(asof_date)

    @relevance = time_relevance(asof_date) # during and up to 3 weeks after current period

    raise EnergySparksNotEnoughDataException, "Not enough data in current period"  unless enough_days_data_for_period(current_period,  asof_date)
    raise EnergySparksNotEnoughDataException, "Not enough data in previous period" unless enough_days_data_for_period(previous_period, asof_date)

    current_period_data = meter_values_period(current_period)
    previous_period_data = normalised_period_data(current_period, previous_period)
    previous_period_data_unadjusted = meter_values_period(current_period)

    @difference_kwh     = current_period_data[:kwh] - previous_period_data[:kwh]
    @difference_£       = current_period_data[:£]   - previous_period_data[:£]
    @difference_percent = difference_kwh  / previous_period_data[:kwh]

    @current_period_kwh         = current_period_data[:kwh]
    @current_period_£           = current_period_data[:£]
    @current_period_start_date  = current_period.start_date
    @current_period_end_date    = current_period.end_date
    @days_in_current_period     = current_period.days
    @name_of_current_period     = current_period_name(current_period)
    @current_period_average_kwh = @current_period_kwh / @days_in_current_period

    @previous_period_kwh          = previous_period_data[:kwh]
    @previous_period_£            = previous_period_data[:£]
    @previous_period_start_date   = previous_period.start_date
    @previous_period_end_date     = previous_period.end_date
    @days_in_previous_period      = previous_period.days
    @name_of_previous_period      = previous_period_name(previous_period)
    @previous_period_average_kwh  = @previous_period_kwh / @days_in_previous_period

    current_period_range = @current_period_start_date..@current_period_end_date
    @current_holiday_temperatures,  @current_holiday_average_temperature = weeks_temperatures(current_period_range)

    previous_period_range = @previous_period_start_date..@previous_period_end_date
    @previous_holiday_temperatures, @previous_holiday_average_temperature = weeks_temperatures(previous_period_range)

    @current_period_kwhs, _avg = formatted_kwh_period_unadjusted(previous_period_range)
    @previous_period_kwhs_unadjusted,  @previous_period_average_kwh_unadjusted = formatted_kwh_period_unadjusted(previous_period_range)

    @current_period_weekly_kwh  = normalised_average_weekly_kwh(current_period,   :kwh)
    @current_period_weekly_£    = normalised_average_weekly_kwh(current_period,   :£)
    @previous_period_weekly_kwh = normalised_average_weekly_kwh(previous_period,  :kwh)
    @previous_period_weekly_£   = normalised_average_weekly_kwh(previous_period,  :£)
    @change_in_weekly_kwh       = @current_period_weekly_kwh - @previous_period_weekly_kwh
    @change_in_weekly_£         = @current_period_weekly_£ - @previous_period_weekly_£
    @change_in_weekly_percent   = @change_in_weekly_kwh / @previous_period_weekly_kwh

    @rating = calculate_rating(@change_in_weekly_percent, @change_in_weekly_£, fuel_type)

    @bookmark_url = add_book_mark_to_base_url(url_bookmark)
    @term = :shortterm
  end
  alias_method :analyse_private, :calculate

  protected def calculate_rating(percentage_difference, financial_difference_£, fuel_type)
    return 10.0 if financial_difference_£.between?(-MINIMUM_DIFFERENCE_FOR_NON_10_RATING_£, MINIMUM_DIFFERENCE_FOR_NON_10_RATING_£)
    ten_rating_range_percent = fuel_type == :electricity ? 0.10 : 0.15 # more latitude for gas
    calculate_rating_from_range(-ten_rating_range_percent, ten_rating_range_percent, percentage_difference)
  end

  protected def last_two_periods(_asof_date)
    raise EnergySparksAbstractBaseClass, "Error: last_two_periods method not implemented for #{self.class.name}"
  end

  protected def fuel_type
    raise EnergySparksAbstractBaseClass, "Error: fuel_type method not implemented for #{self.class.name}"
  end

  private def url_bookmark
    fuel_type == :electricity ? 'ElectricityChange' : 'GasChange'
  end

  protected def configure_models(_asof_date)
    # do nothing in case of electricity
  end

  protected def temperature_adjustment(_date, _asof_date)
    1.0 # no adjustment for electricity, the default
  end

  protected def meter_values_period(current_period)
    {
      kwh:    kwh_date_range(aggregate_meter, current_period.start_date, current_period.end_date, :kwh),
      £:      kwh_date_range(aggregate_meter, current_period.start_date, current_period.end_date, :£)
    }
  end

  protected def normalised_period_data(current_period, previous_period)
    {
      kwh:    normalise_previous_period_data_to_current_period(current_period, previous_period, :kwh),
      £:      normalise_previous_period_data_to_current_period(current_period, previous_period, :£)
    }
  end

  private def formatted_kwh_period_unadjusted(period, data_type = :kwh)
    values = kwhs_date_range(aggregate_meter, period.first, period.last, data_type)
    formatted_values = values.map { |kwh| kwh.round(0) }.join(', ')
    [formatted_values, values.sum / values.length]
  end

  # adjust the previous periods electricity/gas usage to the number of days in the current period
  # by calculating the average weekday usage and average weekend usage, and multiplying
  # by the same number of days in the current holiday
  private def normalise_previous_period_data_to_current_period(current_period, previous_period, data_type)
    current_weekday_dates = SchoolDatePeriod.matching_dates_in_period_to_day_of_week_list(current_period, (1..5).to_a)
    current_weekend_dates = SchoolDatePeriod.matching_dates_in_period_to_day_of_week_list(current_period, [0, 6])

    previous_average_weekdays = average_period_value(previous_period, (1..5).to_a, data_type)
    previous_average_weekends = average_period_value(previous_period, [0, 6], data_type)

    current_weekday_dates.length * previous_average_weekdays + current_weekend_dates.length * previous_average_weekends
  end

  private def normalised_average_weekly_kwh(period, data_type)
    weekday_average = average_period_value(period, (1..5).to_a, data_type)
    weekend_average = average_period_value(period, [0, 6], data_type)
    5.0 * weekday_average + 2.0 * weekend_average
  end

  private def average_period_value(period, days_of_week, data_type)
    dates = SchoolDatePeriod.matching_dates_in_period_to_day_of_week_list(period, days_of_week)
    values = dates.map { |date| kwh_date_range(aggregate_meter, date, date, data_type) }
    values.sum / values.length
  end

  # relevant if asof date immediately at end of period or up to
  # 3 weeks after
  private def time_relevance(asof_date)
    current_period, _previous_period = last_two_periods(asof_date)
    return :not_relevant if current_period.nil?
    # relevant during period, subject to 'enough_data'
    return :relevant if enough_days_in_period(current_period, asof_date)
    days_from_end_of_period_to_asof_date = asof_date - current_period.end_date
    return days_from_end_of_period_to_asof_date.between?(0, DAYS_ALERT_RELEVANT_AFTER_CURRENT_PERIOD) ? :relevant : :not_relevant
  end

  private def enough_days_in_period(period, asof_date)
    asof_date.between?(period.start_date, period.end_date) && enough_days_data(asof_date - period.start_date + 1)
  end

  def enough_data
    return :not_enough if @not_enough_data_exception
    period1, period2 = last_two_periods(@asof_date)
    enough_days_data_for_period(period1, @asof_date) && enough_days_data_for_period(period2, @asof_date) ? :enough : :not_enough
  end

  protected def enough_days_data_for_period(period, asof_date)
    return false if period.nil?
    period_start = [aggregate_meter.amr_data.start_date,  period.start_date].max
    period_end   = [aggregate_meter.amr_data.end_date,    period.end_date, asof_date].min
    days_in_period = period_end - period_start + 1
    enough_days_data(days_in_period)
  end

  private def enough_days_data(days)
    days >= MINIMUM_DAYS_DATA_FOR_RELEVANT_PERIOD
  end

  protected def minimum_days_for_period
    MINIMUM_DAYS_DATA_FOR_RELEVANT_PERIOD
  end

  # returns [ formatted string of 7 temperatures, average for week]
  private def weeks_temperatures(date_range)
    temperatures = date_range.to_a.map { |date| @school.temperatures.average_temperature(date) }
    formatted_temperatures = temperatures.map { |temp| FormatEnergyUnit.format(:temperature, temp) }.join(', ')
    [formatted_temperatures, temperatures.sum / temperatures.length]
  end
end

class AlertHolidayComparisonBase < AlertPeriodComparisonBase
  protected def truncate_period_to_available_meter_data(period)
    return period if period.start_date >= aggregate_meter.amr_data.start_date && period.end_date <= aggregate_meter.amr_data.end_date
    start_date = [period.start_date, aggregate_meter.amr_data.start_date].max
    end_date = [period.end_date, aggregate_meter.amr_data.end_date].min
    SchoolDatePeriod.new(period.type, period.title + ' truncated to available meter data', start_date, end_date) if end_date >= start_date
    nil
  end

  protected def current_period_name(current_period); period_name(current_period) end
  protected def previous_period_name(previous_period); period_name(previous_period) end

  protected def period_name(period); period.type.to_s.humanize end
end