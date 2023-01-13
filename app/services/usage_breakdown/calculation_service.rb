# frozen_string_literal: true

module UsageBreakdown
  class CalculationService
    def initialize; end

    def calculate
      # code extracted from AlertOutOfHoursBaseUsage calculate method to go here
    end

    def calculate_kwh; end

    def calculate_pounds_sterling; end

    def calculate_pounds_current; end

    def calculate_co2; end

    def chart_data_for(chart_identifier)

      # load
      # wrapper class around chart data
      #   kwh:      :alert_daytype_breakdown_electricity_kwh,
      #   co2:      :alert_daytype_breakdown_electricity_co2,
      #   £:        :alert_daytype_breakdown_electricity_£,
      #   £current: :alert_daytype_breakdown_electricity_£current,
    end
  end
end
