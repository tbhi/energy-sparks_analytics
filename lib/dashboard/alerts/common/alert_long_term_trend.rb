class AlertLongTermTrend < AlertAnalysisBase
  attr_reader :this_year_£, :last_year_£, :year_change_£, :relevance
  attr_reader :percent_change_£, :summary, :prefix_1, :prefix_2
  attr_reader :last_year_£_temp_adj, :year_change_£_temp_adj, :percent_change_£_temp_adj

  attr_reader :this_year_co2, :last_year_co2, :year_change_co2, :percent_change_co2
  attr_reader :last_year_co2_temp_adj, :year_change_co2_temp_adj, :percent_change_co2_temp_adj
  attr_reader :degreeday_adjustment, :degreedays_this_year, :degreedays_last_year

  def initialize(school, type = :electricitylongtermtrend)
    super(school, type)
    @relevance = aggregate_meter.nil? ? :never_relevant : :relevant
  end

  def enough_data
    days_amr_data_with_asof_date(@asof_date) > 2 * 365 ? :enough : :not_enough
  end

  def timescale
    'last 2 years'
  end

  def self.long_term_variables(fuel_type)
    {
      this_year_£: {
        description: "This years #{fuel_type} consumption £",
        units:  :£
      },
      last_year_£: {
        description: "Last years #{fuel_type} consumption £",
        units:  :£
      },
      last_year_£_temp_adj: {
        description: "Last years #{fuel_type} consumption £ - temperature adjusted (gas, SH)",
        units:  :£
      },
      year_change_£: {
        description: "Change between this year\'s and last year\'s #{fuel_type} consumption £",
        units:  :£
      },
      year_change_£_temp_adj: {
        description: "Change between this year\'s and last year\'s #{fuel_type} consumption £",
        units:  :£
      },
      percent_change_£: {
        description: "Change between this year\'s and last year\'s #{fuel_type} consumption %  - temperature adjusted (gas, SH)",
        units:  :relative_percent
      },
      percent_change_£_temp_adj: {
        description: "Change between this year\'s and last year\'s #{fuel_type} consumption % - temperature adjusted (gas, SH)",
        units:  :relative_percent
      },
      this_year_co2: {
        description: "This years #{fuel_type} consumption co2",
        units:  :co2
      },
      last_year_co2: {
        description: "Last years #{fuel_type} consumption co2",
        units:  :co2
      },
      last_year_co2_temp_adj: {
        description: "Last years #{fuel_type} consumption co2  - temperature adjusted (gas, SH)",
        units:  :co2
      },
      year_change_co2: {
        description: "Change between this year\'s and last year\'s #{fuel_type} consumption co2",
        units:  :co2
      },
      year_change_co2_temp_adj: {
        description: "Change between this year\'s and last year\'s #{fuel_type} consumption co2  - temperature adjusted (gas, SH)",
        units:  :co2
      },
      percent_change_co2: {
        description: "Change between this year\'s and last year\'s #{fuel_type} consumption %",
        units:  :relative_percent
      },
      percent_change_co2_temp_adj: {
        description: "Change between this year\'s and last year\'s #{fuel_type} consumption %  - temperature adjusted (gas, SH)",
        units:  :relative_percent
      },
      summary: {
        description: 'Change in £spend, relative to previous year',
        units: String
      },
      prefix_1: {
        description: 'Change: up or down',
        units: String
      },
      prefix_2: {
        description: 'Change: increase or reduction',
        units: String
      },
      degreeday_adjustment: {
        description: 'Degree day adjustment (base 15.5C)',
        units: Float
      },
      degreedays_this_year: {
        description: 'Degree days this year (base 15.5C)',
        units: Float
      },
      degreedays_last_year: {
        description: 'Degree days last year  (base 15.5C)',
        units: Float
      },
    }
  end

  def maximum_alert_date
    aggregate_meter.amr_data.end_date
  end

  private def calculate(asof_date)
    raise EnergySparksNotEnoughDataException, "Not enough data: 2 years of data required, got #{days_amr_data} days" if enough_data == :not_enough

    scalar = ScalarkWhCO2CostValues.new(@school)

    @this_year_£          = scalar.aggregate_value({ year:  0 }, fuel_type, :£,   { asof_date: asof_date})
    @last_year_£          = scalar.aggregate_value({ year: -1 }, fuel_type, :£,   { asof_date: asof_date})
    @last_year_£_temp_adj = @last_year_£ * temperature_compensation_factor

    @year_change_£          = @this_year_£ - @last_year_£
    @year_change_£_temp_adj = @this_year_£ - @last_year_£_temp_adj

    @percent_change_£           = @year_change_£ / @last_year_£
    @percent_change_£_temp_adj  = @year_change_£_temp_adj / @last_year_£

    @this_year_co2          = scalar.aggregate_value({ year:  0 }, fuel_type, :co2, { asof_date: asof_date})
    @last_year_co2          = scalar.aggregate_value({ year: -1 }, fuel_type, :co2, { asof_date: asof_date})
    @last_year_co2_temp_adj = @last_year_co2 * temperature_compensation_factor
    
    @year_change_co2          = @this_year_co2 - @last_year_co2
    @year_change_co2_temp_adj = @this_year_co2 - @last_year_co2_temp_adj

    @percent_change_co2          = @year_change_co2 / @last_year_co2
    @percent_change_co2_temp_adj = @year_change_co2 / @year_change_co2_temp_adj

    @prefix_1 = @year_change_£_temp_adj > 0 ? 'up' : 'down'
    @prefix_2 = @year_change_£_temp_adj > 0 ? 'increase' : 'reduction'

    @summary  = summary_text

    @rating = calculate_rating_from_range(-0.1, 0.15, percent_change_£_temp_adj)

    set_savings_capital_costs_payback(Range.new(year_change_£, year_change_£), nil, @year_change_co2)
  end
  alias_method :analyse_private, :calculate

  def summary_text
    FormatEnergyUnit.format(:£, @year_change_£_temp_adj, :text) + 'pa ' +
    @prefix_2 + ' since last year, ' +
    FormatEnergyUnit.format(:relative_percent, @percent_change_£_temp_adj, :text)
  end

  def temperature_compensation_factor
    raise EnergySparksAbstractBaseClass, "Unexpected call to abstract base class for #{self.class.name}"
  end
end

class AlertElectricityLongTermTrend < AlertLongTermTrend
  def self.template_variables
    specific = { 'Electricity long term trend' => long_term_variables('electricity')}
    specific.merge(self.superclass.template_variables)
  end

  def fuel_type
    :electricity
  end

  def temperature_compensation_factor
    1.0
  end

  def aggregate_meter
    @school.aggregated_electricity_meters
  end
end

class AlertGasLongTermTrend < AlertLongTermTrend
  include Logging
  def self.template_variables
    specific = { 'Gas long term trend' => long_term_variables('gas')}
    specific.merge(self.superclass.template_variables)
  end

  def fuel_type
    :gas
  end

  def aggregate_meter
    @school.aggregated_heat_meters
  end

  def temperature_compensation_factor
    scalar = ScalarkWhCO2CostValues.new(@school)

    # aggregate to get dates - inefficient
    y0 = scalar.scalar({ year:   0 }, fuel_type, :£,  { asof_date: @asof_date})
    y1 = scalar.scalar({ year:  -1 }, fuel_type, :£,  { asof_date: @asof_date})

    @degreedays_this_year = @school.temperatures.degree_days_in_date_range(y0[:start_date], y0[:end_date])
    @degreedays_last_year = @school.temperatures.degree_days_in_date_range(y1[:start_date], y1[:end_date])

    @degreeday_adjustment = @degreedays_this_year / @degreedays_last_year
  rescue EnergySparksNotEnoughDataException => e
    logger.info "Model failed: e.message"
    1.0
  end
end
