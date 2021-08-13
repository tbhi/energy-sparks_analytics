# consolidates various adjustments needed to calculate next year's targets
# by 'calculating' underlying AMR data for the last year
# Main adjustments
# - electricity: where less than 1 year's data
#                for COVID lockdown3 where there was a ~20% drop in usage
# - gas:         where there is less than 1 year's data
#
# returns a amr data for meter either the original if no adjustment is necessary
# or adjusted data - going back 1+ year, so next year's target can be calculated
#
class OneYearTargetingAndTrackingAmrData
  def initialize(meter, target_dates)
    @meter = meter
    @target_dates = target_dates
  end

  # returns
  # {
  #   amr_data:             amr data,
  #   percent_real_data:    Float,
  #   adjustments_applied:  text description
  # }
  def last_years_amr_data
    @last_years_amr_data ||= calculate_one_year_historic_synthetic_data
  end

  def annual_kwh_estimate_required?
    # probably unnecessary, to be calculated and marshaled by the front end?
    false
  end

  private

  def calculate_one_year_historic_synthetic_data
    data = calculate_last_years_amr_data
    data[:feedback].merge!(@target_dates.serialised_dates_for_debug)
    data
  end

  def calculate_last_years_amr_data
    case @meter.fuel_type
    when :electricity
      if !@target_dates.full_years_benchmark_data?
        fit_electricity
      elsif seasonal_electricity_covid_adjustment.enough_data?
        seasonal_electricity_covid_adjustment_amr_data
      elsif enough_data?
        enough_data_already
      else
        raise StandardError, 'targeting and tracking electric < 1 year not intergrated yet'
      end
    when :gas
      if @target_dates.full_years_benchmark_data?
        enough_data_already
      else
        full_year_gas_estimate_amr_data
      end
    else
      raise StandardError, "targeting and tracking adjustment for fuel #{@meter.fuel_type} currently not supported"
    end
  end

  def enough_data?
    @meter.enough_amr_data_to_set_target?
  end

  def enough_data_already
    {
      amr_data:             @meter.amr_data,
      feedback: {
        percent_real_data:    1.0,
        adjustments_applied:  "No adjustments necessary as > 1 year data (#{@meter.amr_data.days}) and recent (to #{@meter.amr_data.end_date})",
        rule:                 'Enough data already so no synthetic data'
      }
    }
  end

  def fit_electricity
    electric_estimate = ElectricityEstimation.new(@meter, @target_dates)
    electric_estimate.complete_year_amr_data
  end

  def seasonal_electricity_covid_adjustment
    @seasonal_electricity_covid_adjustment ||= SeasonalMirroringCovidAdjustment.new(@meter, @meter.meter_collection.holidays)
  end

  def seasonal_electricity_covid_adjustment_amr_data
    @seasonal_electricity_covid_adjustment_amr_data ||= seasonal_electricity_covid_adjustment.adjusted_amr_data
  end

  def full_year_gas_estimate
    @full_year_gas_estimate ||= MissingGasEstimation.new(@meter, @meter.annual_kwh_estimate, @target_dates)
  end

  def full_year_gas_estimate_amr_data
    @full_year_gas_estimate_amr_data ||= full_year_gas_estimate.adjusted_amr_data
  end
end
