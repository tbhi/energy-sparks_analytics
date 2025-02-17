# only during holidays this alert send message about heating or hot water
class AlertHeatingHotWaterOnDuringHolidayBase < AlertGasModelBase
  attr_reader :summary, :fuel_type
  attr_reader :holiday_usage_to_date_kwh, :holiday_projected_usage_kwh
  attr_reader :holiday_usage_to_date_£,   :holiday_projected_usage_£
  attr_reader :holiday_usage_to_date_co2, :holiday_projected_usage_co2
  attr_reader :heating_days_so_far_this_holiday, :hotwater_days_so_far_this_holiday

  def initialize(school, fuel_type)
    super(school, :heating_hotwater_on_during_holidays)
    @fuel_type = fuel_type
    @relevance = :never_relevant if @relevance != :never_relevant && non_heating_only
    @relevance = :never_relevant unless @school.holidays.holiday?(@today)
  end

  def self.template_variables
    specific = {'heating/Hotwater on during holidays' => TEMPLATE_VARIABLES}
    specific.merge(self.superclass.template_variables)
  end

  TEMPLATE_VARIABLES = {
    holiday_name: {
      description: 'Name of holiday',
      units:  String,
      benchmark_code: 'hnam',
    },
    holiday_usage_to_date_kwh: {
      description: 'Usage so far this holiday - kwh',
      units:  :kwh
    },
    holiday_projected_usage_kwh: {
      description: 'Projected usage for whole holiday - kwh',
      units:  :kwh
    },
    holiday_usage_to_date_£: {
      description: 'Usage so far this holiday - £',
      units:  :£,
      benchmark_code: '£sfr'
    },
    holiday_projected_usage_£: {
      description: 'Projected usage for whole holiday - £',
      units:  :£,
      benchmark_code: '£pro'
    },
    holiday_usage_to_date_co2: {
      description: 'Usage so far this holiday - co2',
      units:  :co2
    },
    holiday_projected_usage_co2: {
      description: 'Projected usage for whole holiday - co2',
      units:  :co2
    },
    heating_days_so_far_this_holiday: {
      description: 'Number of heating days so far (to analysis date)',
      units:  Integer
    },
    hotwater_days_so_far_this_holiday: {
      description: 'Number of hot water days so far (to analysis date)',
      units:  Integer
    },
    summary: {
      description: 'Summary of holiday usage',
      units:  String
    },
    fuel_type: {
      description: 'Fuel: gas or storage heaters',
      units:  :fuel_type
    },
    heating_type: {
      description: 'gas boiler or storage heaters',
      units:  String,
      benchmark_code: 'ftyp',
    }
  }

  def relevance
    @relevance
  end

  def enough_data
    enough_data_for_model_fit ? :enough : :not_enough
  end

  def time_of_year_relevance
    set_time_of_year_relevance(@relevance == :relevant ? 10.0 : 0.0)
  end

  protected def max_days_out_of_date_while_still_relevant
    14
  end

  def i18n_prefix
    "analytics.#{AlertHeatingHotWaterOnDuringHolidayBase.name.underscore}"
  end

  def timescale
    I18n.t("#{i18n_prefix}.timescale")
  end

  private

  def calculate(asof_date)
    calculate_model(asof_date)

    if @school.holidays.holiday?(asof_date)
      @relevance = :relevant

      @holiday_period      = @school.holidays.holiday(asof_date)
      holiday_date_range  = @holiday_period.start_date..@holiday_period.end_date

      calc = calculate_boiler_usage(holiday_date_range, :kwh, asof_date)
      @holiday_usage_to_date_kwh   = calc[:usage_to_date]
      @holiday_projected_usage_kwh = calc[:projected_usage]

      calc = calculate_boiler_usage(holiday_date_range, :£, asof_date)
      @holiday_usage_to_date_£   = calc[:usage_to_date]
      @holiday_projected_usage_£ = calc[:projected_usage]

      calc = calculate_boiler_usage(holiday_date_range, :co2, asof_date)
      @holiday_usage_to_date_co2   = calc[:usage_to_date]
      @holiday_projected_usage_co2 = calc[:projected_usage]

      boiler_usage = characterise_boiler_usage(holiday_date_range, :kwh, asof_date)
      @heating_days_so_far_this_holiday  = count_days(boiler_usage, :heating)
      @hotwater_days_so_far_this_holiday = count_days(boiler_usage, :hotwater)

      @relevance, @rating = if @holiday_usage_to_date_kwh.zero?
                              [:not_relevant, 10.0]
                            else
                              [:relevant, 0.0]
                            end
    else
      @relevance = :never_relevant

      @holiday_usage_to_date_£   = 0.0
      @holiday_projected_usage_£ = 0.0

      @rating = 10.0
    end

    @summary = summary_text

    @term = :shortterm
  end
  alias_method :analyse_private, :calculate

  def holiday_name
    @holiday_period.nil? ? 'Not a holiday' : @holiday_period.title
  end

  def summary_text
    if @rating == 0.0
      if @heating_days_so_far_this_holiday == 0
        left_on_message = I18n.t("#{i18n_prefix}.only_hotwater",
          hotwater_days: FormatUnit.format(:days, @hotwater_days_so_far_this_holiday))
      elsif @hotwater_days_so_far_this_holiday == 0
        left_on_message = I18n.t("#{i18n_prefix}.only_heating",
          heating_days: FormatUnit.format(:days, @heating_days_so_far_this_holiday))
      else
        left_on_message = I18n.t("#{i18n_prefix}.only_heating",
          hotwater_days: FormatUnit.format(:days, @hotwater_days_so_far_this_holiday),
          heating_days: FormatUnit.format(:days, @heating_days_so_far_this_holiday))
      end
      I18n.t("#{i18n_prefix}.summary",
        heating_type: heating_type,
        holiday_name: holiday_name,
        date: I18n.l(@asof_date, format: '%A %e %b %Y'),
        left_on_message: left_on_message,
        cost: FormatUnit.format(:£, @holiday_usage_to_date_£, :html),
        project_cost: FormatUnit.format(:£, @holiday_projected_usage_£, :html)
      )
      else
        #TODO: message refers to using no gas, but this text also used for storage heaters
        I18n.t("#{i18n_prefix}.heating_not_on")
      end
  end

  def calculate_boiler_usage(holiday_date_range, data_type, asof_date)
    boiler_usage = characterise_boiler_usage(holiday_date_range, data_type, asof_date)

    {
      usage_to_date:   calculate_totals_to_date(boiler_usage),
      projected_usage: calculate_projected_usage(boiler_usage, holiday_date_range)
    }
  end

  def characterise_boiler_usage(holiday_date_range, data_type, asof_date)
    holiday_date_range.map do |date|
      if date.between?(aggregate_meter.amr_data.start_date, [aggregate_meter.amr_data.end_date, asof_date].min)
        [
          date,
          {
            usage:    boiler_usage(date),
            weekend:  weekend?(date),
            val:      aggregate_meter.amr_data.one_day_kwh(date, data_type),
          }
        ]
      else
        [ date, nil ]
      end
    end.to_h
  end

  def weekend?(date)
    [0, 6].include?(date.wday)
  end

  def count_days(calc, usage)
    calc.values.count do |v|
      !v.nil? && v[:usage] == usage
    end
  end

  def calculate_projected_usage(boiler_usage, holiday_date_range)
    projected_weekend_usage = projected_usage_by_daytype(boiler_usage, holiday_date_range, true)
    projected_weekday_usage = projected_usage_by_daytype(boiler_usage, holiday_date_range, false)
    projected_weekend_usage + projected_weekday_usage
  end

  def projected_usage_by_daytype(boiler_usage, holiday_date_range, weekend)
    usage = calculate_average_usage_to_date(boiler_usage, weekend)
    days  = days_in_holiday_by_type(holiday_date_range, weekend)
    usage * days
  end

  def days_in_holiday_by_type(holiday_date_range, weekend)
    holiday_date_range.count do |date|
      weekend == weekend?(date)
    end
  end

  def calculate_average_usage_to_date(boiler_usage, weekend)
    valid_days = boiler_usage.values.compact.select { |v| v[:weekend] == weekend }
    if valid_days.empty?
      0.0
    else
      valid_days.map { |v| v[:val] }.sum / valid_days.length
    end
  end

  def calculate_totals_to_date(boiler_usage)
    valid_days = boiler_usage.values.compact
    valid_days.map { |v| v[:val] }.sum
  end

  def boiler_usage(date)
    if @heating_model.heating_on?(date)
      :heating
    elsif @heating_model.boiler_on?(date)
      :hotwater
    else
      nil
    end
  end
end

class AlertGasHeatingHotWaterOnDuringHoliday < AlertHeatingHotWaterOnDuringHolidayBase
  def initialize(school)
    super(school, :gas)
  end

  def heating_type
    I18n.t("analytics.common.gas_boiler")
  end
end
