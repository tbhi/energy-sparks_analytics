class AlertBaseloadBase < AlertElectricityOnlyBase

  def self.baseload_alerts
    [
      AlertElectricityBaseloadVersusBenchmark,
      AlertChangeInElectricityBaseloadShortTerm,
      AlertSeasonalBaseloadVariation,
      AlertIntraweekBaseloadVariation
    ]
  end

  def initialize(school, report_type, meter = school.aggregated_electricity_meters)
    super(school, report_type)
    @report_type = report_type
    @meter = meter
  end

  def calculate_all_baseload_alerts(asof_date)
    self.class.baseload_alerts.map do |alert_class|
      alert = alert_class.new(@school, @report_type, @meter)
      [
        alert,
        valid_calculation(alert, asof_date)
      ]
    end.to_h
  end

  def timescale
    I18n.t("#{i18n_prefix}.timescale")
  end

  def commentary
    [ { type: :html,  content: 'No advice yet' } ]
  end

  def self.background_and_advice_on_reducing_issue
    []
  end

  private

  def implied_baseload_tariff_rate_£_per_kwh(asof_date = aggregate_meter.amr_data.end_date)
    kwh_x48 = AMRData.single_value_kwh_x48(1.0 / 48.0)
    aggregate_meter.amr_data.economic_cost_for_x48_kwhs(asof_date, kwh_x48)
  end

  def valid_calculation(alert, asof_date)
    return false unless alert.valid_alert?
    alert.analyse(asof_date, true)
    alert.make_available_to_users?
  end

  def format_kw(value)
    FormatEnergyUnit.format(:kw, value, :html)
  end
end
