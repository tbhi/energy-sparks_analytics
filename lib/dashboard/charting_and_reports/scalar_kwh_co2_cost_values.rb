# uses charting aggregation engine to calculate single aggregate
# kWh, CO2, economic cost or accounting cost values over a given
# time period (e.g. :week, :month, :year)
# has to configure a pseudo chart config to tell aggregation
# engine what to do
#
class ScalarkWhCO2CostValues
  def initialize(meter_collection)
    @meter_collection = meter_collection
  end

  def aggregate_value(time_scale, fuel_type, data_type = :kwh)
    check_data_available_for_fuel_type(fuel_type)
    aggregation_configuration(time_scale, fuel_type, data_type)
  end

  private def aggregation_configuration(time_scale, fuel_type, data_type)
    config = {
      name:             'Scalar aggregation request',
      meter_definition: meter_type_from_fuel_type(fuel_type),
      x_axis:           :nodatebuckets,
      series_breakdown: :none,
      yaxis_units:      data_type,
      yaxis_scaling:    :none,
      timescale:        time_scale,

      chart1_type:      :column,
      chart1_subtype:   :stacked
    }
 
    aggregator = Aggregator.new(@meter_collection, config, false)

    aggregator.aggregate

    aggregator.valid ? aggregator.bucketed_data['Energy'][0] : nil
  end

  private def check_data_available_for_fuel_type(fuel_type)
    case fuel_type
    when :gas
      raise EnergySparksNoMeterDataAvailableForFuelType.new('No gas meter data available') unless @meter_collection.gas?
    when :electricity
      raise EnergySparksNoMeterDataAvailableForFuelType.new('No electricity meter data available') unless @meter_collection.electricity?
    when :storage_heaters
      raise EnergySparksNoMeterDataAvailableForFuelType.new('No storage heater meter data available') unless @meter_collection.storage_heaters?
    when solar_pv
      raise EnergySparksNoMeterDataAvailableForFuelType.new('No solar pv meter data available') unless @meter_collection.solar_pv_panels?
      :solar_pv_meter
    else
      raise EnergySparksNoMeterDataAvailableForFuelType.new('Unexpected nil fuel type for scalar energy calculation') if fuel_type.nil?
      raise EnergySparksNoMeterDataAvailableForFuelType.new("Unexpected fuel type #{fuel_type} for scalar energy calculation") 
    end
  end

  private def meter_type_from_fuel_type(fuel_type)
    case fuel_type
    when :gas
      :allheat
    when :electricity
      :allelectricity
    when :storage_heaters
      :storage_heater_meter
    when solar_pv
      :solar_pv_meter
    else
      raise EnergySparksBadChartSpecification.new('Unexpected nil fuel type for scalar energy calculation') if fuel_type.nil?
      raise EnergySparksBadChartSpecification.new("Unexpected fuel type #{fuel_type} for scalar energy calculation") 
    end
  end
end