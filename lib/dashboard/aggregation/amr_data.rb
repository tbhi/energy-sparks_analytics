require_relative '../half_hourly_data'
require_relative '../half_hourly_loader'

class AMRData < HalfHourlyData
  attr_reader :economic_tariff, :accounting_tariff, :carbon_emissions

  class UnexpectedDataType < StandardError; end

  def initialize(type)
    super(type)
    @total = {}
  end

  def self.copy_amr_data(original_amr_data)
    new_amr_data = AMRData.new(original_amr_data.type)
    (original_amr_data.start_date..original_amr_data.end_date).each do |date|
      new_amr_data.add(date, original_amr_data.clone_one_days_data(date))
    end
    new_amr_data
  end

  def set_post_aggregation_state
    @carbon_emissions.post_aggregation_state = true if @carbon_emissions.is_a?(CarbonEmissionsParameterised)
    @economic_tariff.post_aggregation_state = true if @economic_tariff.is_a?(EconomicCostsParameterised)
    @accounting_tariff.post_aggregation_state = true if @accounting_tariff.is_a?(AccountingCostsParameterised)
  end

  def set_economic_tariff(meter)
    logger.info "Creating an economic costs in amr_meter #{meter.mpan_mprn} #{meter.fuel_type}"
    @economic_tariff = EconomicCostsParameterised.create_costs(meter)
  end

  def set_accounting_tariff(meter)
    logger.info "Creating parameterised accounting costs in amr_meter #{meter.mpan_mprn} #{meter.fuel_type}"
    @accounting_tariff = AccountingCostsParameterised.create_costs(meter)
  end

  def set_economic_tariff_schedule(tariff)
    @economic_tariff = tariff
  end

  def set_accounting_tariff_schedule(tariff)
    @accounting_tariff = tariff
  end

  # only accessed for combined meters, where calculation is the summation of 'sub' meters
  def set_carbon_schedule(co2)
    @carbon_emissions = co2
  end

  # access point for single meters, not combined meters
  def set_carbon_emissions(meter_id_for_debug, flat_rate, grid_carbon)
    @carbon_emissions = CarbonEmissionsParameterised.create_carbon_emissions(meter_id_for_debug, self, flat_rate, grid_carbon)
  end

  def add(date, one_days_data)
    raise EnergySparksUnexpectedStateException.new('AMR Data must not be nil') if one_days_data.nil?
    raise EnergySparksUnexpectedStateException.new("AMR Data now held as OneDayAMRReading not #{one_days_data.class.name}") unless one_days_data.is_a?(OneDayAMRReading)
    raise EnergySparksUnexpectedStateException.new("AMR Data date mismatch not #{date} v. #{one_days_data.date}") if date != one_days_data.date
    set_min_max_date(date)

    self[date] = one_days_data

    @total = {}
    @cache_days_totals.delete(date)
  end

  def delete(date)
    super(date)
    @cache_days_totals.delete(date)
  end

  def data(date, halfhour_index)
    raise EnergySparksUnexpectedStateException.new('Deprecated call to amr_data.data()')
  end

  # called from base class histogram function
  def one_days_data_x48(date)
    days_kwh_x48(date)
  end

  def days_kwh_x48(date, type = :kwh)
    check_type(type)
    kwhs = self[date].kwh_data_x48
    return kwhs if type == :kwh
    return @economic_tariff.days_cost_data_x48(date) if type == :£ || type == :economic_cost
    return @accounting_tariff.days_cost_data_x48(date) if type == :accounting_cost
    return @carbon_emissions.one_days_data_x48(date) if type == :co2
  end

  def date_exists_by_type?(date, type)
    check_type(type)
    case type
    when :kwh
      date_exists?(date)
    when :economic_cost, :£
      @economic_tariff.date_exists?(date)
    when :accounting_cost
      @accounting_tariff.date_exists?(date)
    when :co2
      @carbon_emissions.date_exists?(date)
    end
  end

  def check_type(type)
    raise UnexpectedDataType, "Unexpected data type #{type}" unless %i[kwh £ economic_cost co2 accounting_cost].include?(type)
  end

  def substitution_type(date)
    self[date].type
  end

  def substitution_date(date)
    self[date].substitute_date
  end

  def meter_id(date)
   self[date].meter_id
  end

  def days_amr_data(date)
    self[date]
  end

  def self.one_day_zero_kwh_x48
    single_value_kwh_x48(0.0)
  end

  def self.single_value_kwh_x48(kwh)
    Array.new(48, kwh)
  end 

  def self.fast_multiply_x48_x_x48(a, b)
    c = one_day_zero_kwh_x48
    (0..47).each { |x| c[x] = a[x] * b[x] }
    c
  end

  def self.fast_add_x48_x_x48(a, b)
    c = one_day_zero_kwh_x48
    (0..47).each { |x| c[x] = a[x] + b[x] }
    c
  end

  def self.fast_add_multiple_x48_x_x48(list)
    return list.first if list.length == 1
    c = one_day_zero_kwh_x48
    list.each do |data_x48|
      c = fast_add_x48_x_x48(c, data_x48)
    end
    c
  end

  def self.fast_average_multiple_x48(kwhs_x48)
    total = AMRData.fast_add_multiple_x48_x_x48(kwhs_x48)
    AMRData.fast_multiply_x48_x_scalar(total, 1.0 / kwhs_x48.length)
  end

  def self.fast_multiply_x48_x_scalar(a, scalar)
    a.map { |v| v * scalar }
  end

  def set_days_kwh_x48(date, days_kwh_data_x48)
    self[date].set_days_kwh_x48(days_kwh_data_x48)
  end

  def scale_kwh(scale_factor, date1: start_date, date2: end_date)
    (date1..date2).each do |date|
      add(date, OneDayAMRReading.scale(self[date], scale_factor)) if date_exists?(date)
    end
  end

  def kwh(date, halfhour_index, type = :kwh)
    check_type(type)
    return self[date].kwh_halfhour(halfhour_index) if type == :kwh
    return @economic_tariff.cost_data_halfhour(date, halfhour_index) if type == :£ || type == :economic_cost
    return @accounting_tariff.cost_data_halfhour(date, halfhour_index) if type == :accounting_cost
    return @carbon_emissions.co2_data_halfhour(date, halfhour_index) if type == :co2
  end

  def kw(date, halfhour_index)
    kwh(date, halfhour_index) * 2.0
  end

  def set_kwh(date, halfhour_index, kwh)
    self[date].set_kwh_halfhour(halfhour_index, kwh)
  end

  def add_to_kwh(date, halfhour_index, kwh)
    self[date].set_kwh_halfhour(halfhour_index, kwh + kwh(date, halfhour_index))
  end

  def one_day_kwh(date, type = :kwh)
    check_type(type)
    return self[date].one_day_kwh  if type == :kwh
    return @economic_tariff.one_day_total_cost(date) if type == :£ || type == :economic_cost
    return @accounting_tariff.one_day_total_cost(date) if type == :accounting_cost
    return @carbon_emissions.one_day_total(date) if type == :co2
  end

  def clone_one_days_data(date)
    self[date].deep_dup
  end

   # called from inherited half_hourly)data.one_day_total(date), shouldn't use generally
  def one_day_total(date, type = :kwh)
    check_type(type)
    one_day_kwh(date, type)
  end

  def total(type = :kwh)
    check_type(type)
    @total[type] ||= calculate_total(type)
  end

  def calculate_total(type)
    check_type(type)
    t = 0.0
    (start_date..end_date).each do |date|
      t += one_day_kwh(date, type)
    end
    t
  end

  def kwh_date_range(date1, date2, type = :kwh)
    check_type(type)
    return one_day_kwh(date1, type) if date1 == date2
    total_kwh = 0.0
    (date1..date2).each do |date|
      total_kwh += one_day_kwh(date, type)
    end
    total_kwh
  end

  def kwh_period(period)
    kwh_date_range(period.start_date, period.end_date)
  end

  def average_in_date_range(date1, date2, type = :kwh)
    check_type(type)
    kwh_date_range(date1, date2, type) / (date2 - date1 + 1)
  end

  def average_in_date_range_ignore_missing(date1, date2, type = :kwh)
    check_type(type)
    kwhs = []
    (date1..date2).each do |date|
      kwhs.push(one_day_kwh(date, type)) if date_exists?(date)
    end
    kwhs.empty? ? 0.0 : (kwhs.inject(:+) / kwhs.length)
  end

  def kwh_date_list(dates, type = :kwh)
    check_type(type)
    total_kwh = 0.0
    dates.each do |date|
      total_kwh += one_day_kwh(date, type)
    end
    total_kwh
  end

  def baseload_kw(date)
    statistical_baseload_kw(date)
  end

  def overnight_baseload_kw(date)
    raise EnergySparksNotEnoughDataException.new("Missing electric data (2) for #{date}") if date_missing?(date)
    baseload_kw_between_half_hour_indices(date, 41, 47)
  end

  def average_overnight_baseload_kw_date_range(date1, date2)
    overnight_baseload_kwh_date_range(date1, date2) / (date2 - date1 + 1)
  end

  def overnight_baseload_kwh_date_range(date1, date2)
    total = 0.0
    (date1..date2).each do |date|
      raise EnergySparksNotEnoughDataException.new("Missing electric data for #{date}") if !self.key?(date)
      total += overnight_baseload_kw(date)
    end
    total
  end

  def baseload_kw_between_half_hour_indices(date, hhi1, hhi2)
    total_kwh = 0.0
    count = 0
    if hhi2 > hhi1 # same day
      (hhi1..hhi2).each do |halfhour_index|
        total_kwh += kwh(date, halfhour_index)
        count += 1
      end
    else
      (hhi1..48).each do |halfhour_index| # before midnight
        total_kwh += kwh(date, halfhour_index)
        count += 1
      end
      (0..hhi2).each do |halfhour_index| # after midnight
        total_kwh += kwh(date, halfhour_index)
        count += 1
      end
    end
    total_kwh * 2.0 / count
  end

  # alternative heuristic for baseload calculation (for storage heaters)
  # find the average of the bottom 8 samples (4 hours) in a day
  def statistical_baseload_kw(date)
    days_data = days_kwh_x48(date) # 48 x 1/2 hour kWh
    sorted_kwh = days_data.clone.sort
    lowest_sorted_kwh = sorted_kwh[0..7]
    average_kwh = lowest_sorted_kwh.inject { |sum, el| sum + el }.to_f / lowest_sorted_kwh.size
    average_kwh * 2.0 # convert to kW
  end

  def statistical_peak_kw(date)
    days_data = days_kwh_x48(date) # 48 x 1/2 hour kWh
    sorted_kwh = days_data.clone.sort
    highest_sorted_kwh = sorted_kwh[45..47]
    average_kwh = highest_sorted_kwh.inject { |sum, el| sum + el }.to_f / highest_sorted_kwh.size
    average_kwh * 2.0 # convert to kW
  end

  def peak_kw_kwh_date_range(date1, date2)
    total = 0.0
    (date1..date2).each do |date|
      total += peak_kw(date)
    end
    total
  end

  def peak_kw(date)
    days_kwh_x48(date).sort.last * 2.0 # 2.0 = half hour kWh to kW
  end

  def peak_kw_date_range_with_dates(date1 = start_date, date2 = end_date, top_n = 1)
    peaks_by_day = peak_kws_date_range(date1, date2)
    reverse_sorted_peaks = peaks_by_day.sort_by {|_date, kw| -kw}
    if top_n.nil?
      return reverse_sorted_peaks
    else
      return Hash[reverse_sorted_peaks[0...top_n]]
    end
  end

  def peak_kws_date_range(date1 = start_date, date2 = end_date)
    daily_peaks = {}
    (date1..date2).each do |date|
      daily_peaks[date] = peak_kw(date)
    end
    daily_peaks
  end

  def average_baseload_kw_date_range(date1, date2)
    baseload_kwh_date_range(date1, date2) / (date2 - date1 + 1)
  end

  def baseload_kwh_date_range(date1, date2)
    total = 0.0
    (date1..date2).each do |date|
      total += baseload_kw(date)
    end
    total
  end

  def self.create_empty_dataset(type, start_date, end_date, reading_type = 'ORIG')
    data = AMRData.new(type)
    (start_date..end_date).each do |date|
      data.add(date, OneDayAMRReading.new('Unknown', date, reading_type, nil, DateTime.now, one_day_zero_kwh_x48))
    end
    data
  end

  # long gaps are demarked by a single LGAP meter reading - the last day of the gap
  # data held in the database doesn't store the date as part of its meta data so its
  # set here by calling this function after all meter readings are loaded
  def set_long_gap_boundary
    override_start_date = nil
    override_end_date = nil
    (start_date..end_date).each do |date|
      one_days_data = self[date]
      override_start_date = date if !one_days_data.nil? && (one_days_data.type == 'LGAP' || one_days_data.type == 'FIXS')
      override_end_date = date if !one_days_data.nil? && one_days_data.type == 'FIXE'
    end
    unless override_start_date.nil?
      logger.info "Overriding start_date of amr data from #{self.start_date} to #{override_start_date}"
      set_start_date(override_start_date)
    end
    unless override_end_date.nil?
      logger.info "Overriding end_date of amr data from #{self.end_date} to #{override_end_date}"
      set_end_date(override_end_date) unless override_end_date.nil?
    end
  end

  def summarise_bad_data
    date, one_days_data = self.first
    logger.info '=' * 80
    logger.info "Bad data for meter #{one_days_data.meter_id}"
    logger.info "Valid data between #{start_date} and #{end_date}"
    key, _value = self.first
    if key < start_date
      logger.info "Ignored data between #{key} and #{start_date} - because of long gaps"
    end
    bad_data_stats = bad_data_count
    percent_bad = 100.0
    if bad_data_count.key?('ORIG')
      percent_bad = (100.0 * (length - bad_data_count['ORIG'].length)/length).round(1)
    end
    logger.info "bad data summary: #{percent_bad}% substituted"
    bad_data_count.each do |type, dates|
      type_description = sprintf('%-60.60s', OneDayAMRReading.amr_types[type][:name])
      logger.info " #{type}: #{type_description} * #{dates.length}"
      if type != 'ORIG'
        cpdp = CompactDatePrint.new(dates)
        cpdp.log
      end
    end
    bad_dates = dates_with_non_finite_values
    logger.info "bad non finite data on these dates: #{bad_dates.join(';')}" unless bad_dates.empty?
  end

  def dates_with_non_finite_values(sd = start_date, ed = end_date)
    list = []
    (sd..ed).each do |date|
      next if date_missing?(date)
      list.push(date) if days_kwh_x48(date).any?{ |kwh| kwh.nil? || !kwh.finite? }
    end
    list
  end

    # take one set (dd_data) of half hourly data from self
  # - avoiding performance hit of taking a copy
  # caller expected to ensure start and end dates reasonable
  def minus_self(dd_data, min_value = nil)
    sd = start_date > dd_data.start_date ? start_date : dd_data.start_date
    ed = end_date < dd_data.end_date ? end_date : dd_data.end_date
    (sd..ed).each do |date|
      (0..47).each do |halfhour_index|
        updated_kwh = kwh(date, halfhour_index) - dd_data.kwh(date, halfhour_index)
        if min_value.nil?
          set_kwh(date, halfhour_index, updated_kwh)
        else
          set_kwh(date, halfhour_index, updated_kwh > min_value ? updated_kwh : min_value)
        end
      end
    end
  end

  private

  # go through amr_data creating 'histogram' of type of amr_data by type (original data v. substituted)
  # returns {type} = [list of dates of that type]
  def bad_data_count
    bad_data_type_count = {}
    (start_date..end_date).each do |date|
      one_days_data = self[date]
      unless bad_data_type_count.key?(one_days_data.type)
        bad_data_type_count[one_days_data.type] = []
      end
      bad_data_type_count[one_days_data.type].push(date)
    end
    bad_data_type_count
  end
end
