module MeterReadingsFeeds
  class N3rgyData
    include Logging

    KWH_PER_M3_GAS = 11.1 # this depends on the calorifc value of the gas and so is an approximate average

    # N3RGY_DATA_BASE_URL : 'https://api.data.n3rgy.com/' or 'https://sandboxapi.data.n3rgy.com/'

    def initialize(api_key: ENV['N3RGY_API_KEY'], base_url: ENV['N3RGY_DATA_BASE_URL'], debugging: nil, bad_electricity_standing_charge_units: ENV['N3RGY_BAD_UNITS'])
      @api_key = api_key
      @base_url = base_url
      @debugging = debugging
      @bad_electricity_standing_charge_units = bad_electricity_standing_charge_units
    end

    def readings(mpxn, fuel_type, start_date, end_date)
      meter_readings = meter_readings_kwh(mpxn, fuel_type, start_date, end_date)
      { fuel_type =>
          {
            mpan_mprn:        mpxn,
            readings:         make_one_day_readings(meter_readings[:readings], mpxn, start_date, end_date),
            missing_readings: meter_readings[:missing_readings]
          }
      }
    end

    def tariffs(mpxn, fuel_type, start_date, end_date)
      tariff_details = meter_tariffs(mpxn, fuel_type, start_date, end_date)
      {
        kwh_tariffs:      tariff_details[:readings],
        standing_charges: tariff_details[:standing_charges],
        missing_readings: tariff_details[:missing_readings],
      }
    end

    def inventory(mpxn)
      details = api.read_inventory(mpxn: mpxn)
      # seems like requesting file too soon causes Access Denied response
      sleep(1.5)
      api.fetch(details['uri'])
    end

    private

    def meter_tariffs(mpxn, fuel_type, start_date, end_date)
      raw_£ = tariff_data(mpxn, fuel_type, start_date, end_date)
      dt_to_£ = format_tariffs(raw_£[:prices])
      tariffs = convert_dt_to_v_to_date_to_v_x48(start_date, end_date, dt_to_£)
      tariffs[:standing_charges] = format_standing_charges(raw_£[:standing_charges], fuel_type)
      tariffs
    end

    def format_standing_charges(standing_charges_date_str, fuel_type)
      standing_charges_date_str.map do |standing_charge|
        [Date.parse(standing_charge['startDate']), convert_to_£(standing_charge['value'], fuel_type)]
      end.to_h
    end

    def format_tariffs(raw_£)
      raw_£.map do |tariff|
        [DateTime.parse(tariff['timestamp']), convert_to_£(tariff_price(tariff))]
      end.to_h
    end

    def tariff_price(tariff)
      tariff['prices'] ? tariff['prices'][0]['value'] : tariff['value']
    end

    # quote from N3rgy support:
    # "in sandbox environment, electricity tariffs have the standing charges in £/day and the TOU prices in pence/kWh. Gas tariffs are in pence/day and pence/kWh.
    # However, in live environment, our system returns always pence/day and pence/kWh."
    def convert_to_£(value, fuel_type = nil)
      if (fuel_type == :electricity && @bad_electricity_standing_charge_units)
        value
      else
        value / 100.0
      end
    end




    def meter_readings_kwh(mpxn, fuel_type, start_date, end_date)
      dt_to_kwh = consumption_data(mpxn, fuel_type, start_date, end_date)
      convert_dt_to_v_to_date_to_v_x48(start_date, end_date, dt_to_kwh)
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

    def tariff_data(mpxn, fuel_type, start_date, end_date)
      standing_charges = []
      prices = []
      (start_date..end_date).each_slice(90) do |date_range_max_90days|
        response = api.get_tariff_data(mpxn: mpxn,
                                       fuel_type: fuel_type.to_s,
                                       start_date: date_range_max_90days.first,
                                       end_date: date_range_max_90days.last)
        response['values'].each do |tariff|
          standing_charges += tariff['standingCharges']
          prices += tariff['prices']
        end
      end
      {
        standing_charges: standing_charges,
        prices:           prices
      }
    end

    def unit_adjusted_readings(raw_kwhs, units)
      adjust_kwh_units = unit_adjustment(units)
      raw_kwhs.map do |reading|
        [
          DateTime.parse(reading['timestamp']),
          reading['value'] * adjust_kwh_units
        ]
      end
    end

    def unit_adjustment(units)
      units == 'm3' ? KWH_PER_M3_GAS : 1.0
    end

    def make_one_day_readings(meter_readings_by_date, mpan_mprn, start_date, end_date)
      meter_readings_by_date.map do |date, readings|
        [date, OneDayAMRReading.new(mpan_mprn, date, 'ORIG', nil, DateTime.now, readings)]
      end.to_h
    end

    def convert_dt_to_v_to_date_to_v_x48(start_date, end_date, dt_to_kwh)
      missing_readings = []
      readings = Hash.new { |h, k| h[k] = Array.new(48, 0.0) }

      # iterate through data at fixed time intervals
      # so missing date times can be spotted
      (start_date..end_date).each do |date|
        (0..23).each do |hour|
          [0, 30].each_with_index do |mins30, hh_index|
            dt = datetime_to_30_minutes(date, hour, mins30)
            if dt_to_kwh.key?(dt)
              readings[date][hour * 2 + hh_index] = dt_to_kwh[dt]
            else
              missing_readings.push(dt)
            end
          end
        end
      end
      {
        readings:         readings,
        missing_readings: missing_readings
      }
    end

    def datetime_to_30_minutes(date, hour, mins)
      DateTime.new(date.year, date.month, date.day, hour, mins, 0)
    end

    def api
      @api ||= N3rgyDataApi.new(@api_key, @base_url, @debugging)
    end
  end
end
