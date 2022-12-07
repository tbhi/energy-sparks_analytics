class EconomicTariffsChangeCaveats
  def initialize(school)
    @school = school
  end

  def tariff_text_with_sentence(electricity_usage, gas_usage, preamble: '', epilogue: '', charts: false, savings_use_current_tariff_text: false)
    electric_txt    = electricity_usage ? economic_tariff_changed_text(:electricity) : ''
    gas_txt         = gas_usage         ? economic_tariff_changed_text(:gas) : ''
    any_changed_txt = (electric_txt + gas_txt).strip.length > 0
    txt = %(
      <p>
        <%= preamble %>
        <%= electric_txt + gas_txt %>
        <% if savings_use_current_tariff_text %>
          Any savings quoted here are estimates using your latest tariff.
        <% end %>
        <% if any_changed_txt && charts %>
          This change will also be visible on the charts if you select &pound; as the y-axis.
        <% end %>
        <%= epilogue %>
      </p>
    )
    ERB.new(txt).result(binding)
  end

  def tariff_text(electricity_usage, gas_usage)
    tariff_text_with_sentence(electricity_usage, gas_usage)
  end

  def economic_tariff_changed_text(fuel_type)
    info = economic_tariff_changed_information(fuel_type)

    return '' if info.nil?

    return '' if info[:percent_change].magnitude < 0.02

    format_economic_tariff_changed_text(info, fuel_type)
  end

  private

  def percent_change_adjective(pct)
    pct > 0.0 ? 'increase' : 'reduce'
  end

  def format_economic_tariff_changed_text(info, fuel_type)
    date = info[:last_change_date].strftime('%A %d %b %Y')
    rate_before   = FormatEnergyUnit.format(:£_per_kwh, info[:rate_before_£_per_kwh])
    rate_after    = FormatEnergyUnit.format(:£_per_kwh, info[:rate_after_£_per_kwh])
    pct           = FormatEnergyUnit.format(:percent,   info[:percent_change].magnitude)
    pct_adjective = percent_change_adjective(info[:percent_change])

    "Your #{fuel_type.to_s} tariffs have changed in the last year, the last change was on #{date}, " +
    "before this date the average tariff was #{rate_before}, and since it is #{rate_after}. " +
    "This will #{pct_adjective} your #{fuel_type.to_s} costs by #{pct} going forward. "
  end

  def economic_tariff_changed_information(fuel_type)
    meter = meter_for_fuel_type(fuel_type)
    return nil if meter.nil?

    start_date = [meter.amr_data.end_date - 365, meter.amr_data.start_date].max
    end_date = meter.amr_data.end_date

    changed = meter.meter_tariffs.meter_tariffs_differ_within_date_range?(start_date, end_date)

    changed_dates = meter.meter_tariffs.tariff_change_dates_in_period(start_date, end_date)
    last_change_date = changed_dates.last

    return nil if changed_dates.empty?

    # meter.meter_tariffs.print_formatted_constitiuent_meter_tariffs(start_date, end_date)

    before = meter.amr_data.blended_£_per_kwh_date_range(start_date,      last_change_date - 1)
    after = meter.amr_data.blended_£_per_kwh_date_range(last_change_date, end_date)
    {
      last_change_date:       last_change_date,
      rate_before_£_per_kwh:  before,
      rate_after_£_per_kwh:   after,
      percent_change:         (after - before) / before
    }
  end

  def meter_for_fuel_type(fuel_type)
    case fuel_type
    when :electricity
      @school.aggregated_electricity_meters
    when :gas
      @school.aggregated_heat_meters
    when :storage_heater
      @school.storage_heater_meter
    else
      raise EnergySparksUnexpectedStateException, "Unexpected fuel_type #{fuel_type}"
    end
  end
end
