require 'csv'
require 'logger'

# 'base' class used for holding hald hourly data typical to schools' energy analysis
# generally data held in derived classes e.g. temperatures, solar insolence, AMR data
# hash of date => 48 x float values
class HalfHourlyData < Hash
  attr_reader :type, :validated
  def initialize(type)
    @min_date = Date.new(4000, 1, 1)
    @max_date = Date.new(1000, 1, 1)
    @validated = false
    @type = type
    @cache_days_totals = {} # speed optimisation cache[date] = total of 48x 1/2hour data
  end

  def add(date, half_hourly_data_x48)
    set_min_max_date(date)

    self[date] = half_hourly_data_x48

    data_count = validate_data(half_hourly_data_x48)

    if data_count != 48
      puts "Missing data: #{date}: only #{data_count} of 48"
    end
  end

  def missing_dates
    dates = []
    (@min_date..@max_date).each do |date|
      if !self.key?(date)
        dates.push(date)
      end
    end
    dates
  end

  def validate_data(half_hourly_data_x48)
    total = 0
    data_count = 0
    (0..47).each do |i|
      if half_hourly_data_x48[i].is_a?(Float) || half_hourly_data_x48[i].is_a?(Integer)
        total = total + half_hourly_data_x48[i]
        data_count = data_count + 1
      end
    end

    data_count
  end

  # first and last dates maintained manually as the data is held in a hash for speed of access by date
  def set_min_max_date(date)
    if date < @min_date
      @min_date = date
    end
    if date > @max_date
      @max_date = date
    end
  end

  # half_hour_index is 0 to 47, i.e. the index for the half hour within the day
  def data(date, half_hour_index)
    self[date][half_hour_index]
  end

  def one_day_total(date)
    unless @cache_days_totals.key?(date) # perforance optimisation, needs rebenchmarking to check its an actual speedup
      total = self[date].inject(:+)
      @cache_days_totals[date] = total
      return total
    end
    @cache_days_totals[date]
  end

  def start_date
    @min_date
  end

  def end_date
    @max_date
  end

  def set_min_date(min_date)
    @min_date = min_date
  end

  def set_max_date(max_date)
    @max_date = max_date
  end

  def set_validated(valid)
    @validated = valid
  end

  # probably slow
  def all_dates
    self.keys.sort
  end

  # returns an array of DatePeriod - 1 for each acedemic years, with most recent year first
  def academic_years(holidays)
    puts "Warning: depricated from this location please use version in Class Holidays"
    holidays.academic_years(start_date, end_date)
  end

  def nearest_previous_saturday(date)
    while date.wday != 6
      date -= 1
    end
    date
  end
end

class HalfHourlyLoader
  def initialize(csv_file, date_column, data_start_column, header_rows, data)
    @data_start_column = data_start_column
    @date_column = date_column
    @header_rows = header_rows
    read_csv(csv_file, data)
  end

  def read_csv(csv_file, data)
    puts "Reading #{data.type} data from '#{csv_file} date column = #{@date_column} data starts at col #{@data_start_column} skipping #{@header_rows} header rows"
    datareadings = Roo::CSV.new(csv_file)
    line_count = 0
    skip_rows = @header_rows
    datareadings.each do |reading|
      line_count += 1
      if skip_rows.zero?
        begin
          date = Date.parse(reading[@date_column])
          rowdata = reading[@data_start_column, @data_start_column + 47]
          rowdata = rowdata.map(&:to_f)
          data.add(date, rowdata)
        rescue StandardError => e
          puts e.message
          puts e.backtrace.join("\n")
          puts "Unable to read data on line #{line_count} of file #{csv_file} date value #{reading[@date_column]}"
        end
      else
        skip_rows -= 1
      end
    end
    puts "Read hash #{data.length} rows"
  end
end
