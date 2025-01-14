module MeterReadingsFeeds
  class N3rgyData
    include Logging

    class MissingConfig < StandardError; end
    class BadParameters < StandardError; end

    RETRY_INTERVAL = 2
    MAX_RETRIES = 4

    KWH_PER_M3_GAS = 11.1 # this depends on the calorifc value of the gas and so is an approximate average

    def initialize(api_key:, base_url:, bad_electricity_standing_charge_units: false)
      @api_key = api_key
      @base_url = base_url
      @bad_electricity_standing_charge_units = bad_electricity_standing_charge_units
    end

    def readings(mpxn, fuel_type, start_date, end_date)
      raise BadParameters.new("Please specify start and end date") if start_date.nil? || end_date.nil?
      if fuel_type == :exported_solar_pv
        readings_by_date = production_data(mpxn, fuel_type, start_date, end_date)
      else
        readings_by_date = consumption_data(mpxn, fuel_type, start_date, end_date)
      end
      meter_readings = X48Formatter.convert_dt_to_v_to_date_to_v_x48(start_date.to_date, end_date.to_date, readings_by_date, true, nil)
      { fuel_type =>
          {
            mpan_mprn:        mpxn,
            readings:         make_one_day_readings(meter_readings[:readings], mpxn),
            missing_readings: meter_readings[:missing_readings]
          }
      }
    end

    def tariffs(mpxn, fuel_type, start_date, end_date)
      raise BadParameters.new("Please specify start and end date") if start_date.nil? || end_date.nil?
      tariff_details = tariff_data(mpxn, fuel_type, start_date, end_date)
      charges_by_date = tariff_details[:standing_charges].to_h
      prices_by_date = tariff_details[:prices].to_h
      tariff_readings = X48Formatter.convert_dt_to_v_to_date_to_v_x48(start_date.to_date, end_date.to_date, prices_by_date)
      {
        kwh_tariffs:      deduplicate_prices(tariff_readings[:readings]),
        standing_charges: charges_by_date,
        missing_readings: tariff_readings[:missing_readings],
      }
    end

    def inventory(mpxn)
      details = api.read_inventory(mpxn: mpxn)
      api.fetch(details['uri'], RETRY_INTERVAL, MAX_RETRIES)
    end

    def status(mpxn)
      api.status(mpxn)
      :available
    rescue MeterReadingsFeeds::N3rgyDataApi::NotFound
      :unknown
    rescue MeterReadingsFeeds::N3rgyDataApi::NotAllowed
      :consent_required
    end

    def find(mpxn)
      api.find(mpxn)
      true
    rescue MeterReadingsFeeds::N3rgyDataApi::NotFound
      false
    end

    def list
      resp = api.list
      resp['entries']
    end

    def elements(mpxn, fuel_type, reading_type=MeterReadingsFeeds::N3rgyDataApi::DATA_TYPE_CONSUMPTION)
      elements = api.get_elements(mpxn: mpxn, fuel_type: fuel_type, reading_type: reading_type)
      elements['entries']
    end

    def tariffs_available_date_range(mpxn, fuel_type)
      result = api.get_tariff_data(mpxn: mpxn, fuel_type: fuel_type)
      available_date_range(result['availableCacheRange'])
    end

    def readings_available_date_range(mpxn, fuel_type)
      result = api.get_consumption_data(mpxn: mpxn, fuel_type: fuel_type)
      available_date_range(result['availableCacheRange'])
    end

    # PH test
    def cache_start_datetime(mpxn: nil, fuel_type: nil, element: MeterReadingsFeeds::N3rgyDataApi::DEFAULT_ELEMENT, reading_type: MeterReadingsFeeds::N3rgyDataApi::DATA_TYPE_CONSUMPTION)
      start_date = cache_data(mpxn: mpxn, fuel_type: fuel_type, element: element, reading_type: reading_type, type: 'start')
      DateTime.strptime(start_date, '%Y%m%d%H%M')
    end

    # PH test
    def cache_end_datetime(mpxn: nil, fuel_type: nil, element: MeterReadingsFeeds::N3rgyDataApi::DEFAULT_ELEMENT, reading_type: MeterReadingsFeeds::N3rgyDataApi::DATA_TYPE_CONSUMPTION)
      end_date = cache_data(mpxn: mpxn, fuel_type: fuel_type, element: element, reading_type: reading_type, type: 'end')
      DateTime.strptime(end_date, '%Y%m%d%H%M')
    end

    def consumption_data(mpxn, fuel_type, start_date, end_date)
      readings = []
      (start_date..end_date).each_slice(90) do |date_range_max_90days|
        response = api.get_consumption_data(mpxn: mpxn,
                                            fuel_type: fuel_type.to_s,
                                            start_date: date_range_max_90days.first,
                                            end_date: date_range_max_90days.last)
        readings += unit_adjusted_readings(response['values'], response['unit'])
      end
      readings.to_h
    end

    def production_data(mpxn, fuel_type, start_date, end_date)
      readings = []
      (start_date..end_date).each_slice(90) do |date_range_max_90days|
        response = api.get_production_data(mpxn: mpxn,
                                            fuel_type: fuel_type.to_s,
                                            start_date: date_range_max_90days.first,
                                            end_date: date_range_max_90days.last)
        readings += unit_adjusted_readings(response['values'], response['unit'])
      end
      readings.to_h
    end

    def tariff_data(mpxn, fuel_type, start_date, end_date)
      standing_charges = []
      prices = []
      (start_date..end_date).each_slice(90) do |date_range_max_90days|
        response = api.get_tariff_data(mpxn: mpxn,
                                       fuel_type: fuel_type.to_s,
                                       start_date: date_range_max_90days.first,
                                       end_date: date_range_max_90days.last)
        response['values'].each do |tariff|
          standing_charges += unit_adjusted_standing_charges(tariff['standingCharges'], fuel_type)
          prices += unit_adjusted_prices(tariff['prices'])
        end
      end
      {
        standing_charges: deduplicate_standing_charges(standing_charges),
        prices:           prices
      }
    end

    private

    def deduplicate_standing_charges(ary)
      N3rgyDataDeduplicator.deduplicate_standing_charges(ary)
    end

    def deduplicate_prices(hsh)
      N3rgyDataDeduplicator.deduplicate_prices(hsh)
    end

    def unit_adjusted_readings(raw_readings, units)
      adjust_kwh_units = to_kwh(units)
      raw_readings.map do |reading|
        [
          DateTime.parse(reading['timestamp']),
          reading['value'].nil? ? nil : reading['value'] * adjust_kwh_units
        ]
      end
    end

    def unit_adjusted_prices(raw_prices)
      raw_prices.map do |price|
        [
          DateTime.parse(price['timestamp']),
          convert_to_£(tariff_price(price))
        ]
      end
    end

    def unit_adjusted_standing_charges(raw_standing_charges, fuel_type)
      raw_standing_charges.map do |standing_charge|
        [
          Date.parse(standing_charge['startDate']),
          convert_to_£(standing_charge['value'], fuel_type)
        ]
      end
    end

    def to_kwh(units)
      units == 'm3' ? KWH_PER_M3_GAS : 1.0
    end

    def tariff_price(tariff)
      tariff['prices'] ? tiered_tariff(tariff) : tariff['value']
    end

    def tiered_tariff(tariff)
      # index tiered tariff by index as there is nothing in the documentation
      # to indicate that anything other than the 'index' defines the ordering and
      # association of thresholds with prices, there is always 1 less threshold
      # than value, the last price without a threshold goes to infinity
      tariffs = tariff['prices'].map{ |price| [ price['index'], price['value'] ] }.to_h
      thresholds = tariff['thresholds'].map{ |price| [ price['index'], price['value'] ] }.to_h
      {
        type:       :tiered,
        tariffs:    tariffs,
        thresholds: thresholds
      }
    end

    # quote from N3rgy support:
    # "in sandbox environment, electricity tariffs have the standing charges in £/day and the TOU prices in pence/kWh. Gas tariffs are in pence/day and pence/kWh.
    # However, in live environment, our system returns always pence/day and pence/kWh."
    def convert_to_£(value, fuel_type = nil)
      if value.is_a?(Hash)
        convert_tiered_prices(value, fuel_type)
      else
        convert_one_value_to_£(value, fuel_type)
      end
    end

    def convert_tiered_prices(values, fuel_type)
      values[:tariffs].transform_values! { |value| convert_one_value_to_£(value, fuel_type) }
      values
    end

    def convert_one_value_to_£(value, fuel_type)
      if (fuel_type == :electricity && @bad_electricity_standing_charge_units)
        value
      else
        value / 100.0
      end
    end

    def available_date_range(dates)
      if dates
        start_date = DateTime.parse(dates['start']) if dates['start']
        end_date = DateTime.parse(dates['end']) if dates['end']
        if start_date && end_date
          return (start_date.next_day..end_date)
        end
      end
    rescue => e
      nil
    end

    # PH test
    def cache_data(mpxn:, fuel_type:, element:, reading_type:, type:)
      api.cache_data(mpxn: mpxn, fuel_type: fuel_type, element: element, reading_type: reading_type)['availableCacheRange'][type]
    end

    def make_one_day_readings(meter_readings_by_date, mpan_mprn)
      meter_readings_by_date.map do |date, readings|
        [date.to_date, OneDayAMRReading.new(mpan_mprn, date.to_date, 'ORIG', nil, DateTime.now, readings, true)]
      end.to_h
    end

    def api
      raise MissingConfig.new("Apikey must be set") unless @api_key.present?
      raise MissingConfig.new("Base URL must be set") unless @base_url.present?
      @api ||= N3rgyDataApi.new(@api_key, @base_url)
    end
  end
end
