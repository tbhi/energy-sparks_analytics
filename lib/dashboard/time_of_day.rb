# time of day (differentiates between 00:00 and 24:00)
class TimeOfDay
  include Comparable

  attr_reader :hour, :minutes, :relative_time

  def initialize(hour, minutes)
    if hour.nil? || minutes.nil? || hour < 0 || hour > 24 || minutes < 0 || minutes >= 60 || (hour == 24 && minutes != 0)
      raise EnergySparksUnexpectedStateException.new("Unexpected time of day setting #{hour}:#{minutes}")
    end
    @hour = hour
    @minutes = minutes
    # PH 24Oct2020: make .minutes '.to_i' after
    # hour = 5 minutes = 57.000000000000014 => "invalid fraction"
    @relative_time = DateTime.new(1970, 1, 1, hour, minutes.to_i, 0)
  end

  def to_time
    @relative_time.to_time
  end

  def on_30_minute_interval?
    [0, 30].include?(minutes)
  end

  def self.time_of_day_from_halfhour_index(hh)
    TimeOfDay.new((hh / 2).to_i, 30 * (hh % 2))
  end

  def self.from_hour_fraction(hours_fraction)
    TimeOfDay.new(hours_fraction.to_i, 60 * (hours_fraction - hours_fraction.to_i))
  end

  def self.time_of_day_since_midnight(minutes_since_midnight)
    hours = (minutes_since_midnight / 60).to_i
    minutes = (minutes_since_midnight - hours * 60).to_i
    TimeOfDay.new(hours, minutes)
  end

  def self.average_time_of_day(time_of_days)
    times = time_of_days.map(&:to_time)
    t = Time.at(times.map(&:to_i).reduce(:+) / times.size)
    TimeOfDay.new(t.hour, t.min)
  end

  def self.add_hours_and_minutes(time_of_day, add_hours, add_minutes = 0.0)
    t = time_of_day.relative_time
    t += add_hours * 60 * 60 + add_minutes * 60
    TimeOfDay.new(t.hour, t.min)
  end

  def to_s
    if @relative_time.day == 1
      @relative_time.strftime('%H:%M')
    elsif @relative_time.day == 2 && @relative_time.hour == 0
      @relative_time.strftime('24:%M')
    else
      '??:??'
    end
  end

  def inspect
    to_s
  end

  # returns the halfhour index in which the time of day starts,
  # plus the proportion of the way through the half hour bucket the time is
  # code obscificated for performancce
  def to_halfhour_index_with_fraction
    if @minutes == 0
      [@hour * 2, 0.0]
    elsif @minutes == 30
      [@hour * 2 + 1, 0.0]
    elsif @minutes >= 30
      [@hour * 2 + 1, (@minutes - 30) / 30.0]
    else
      [@hour * 2, @minutes / 30.0]
    end
  end

  def to_halfhour_index
    to_halfhour_index_with_fraction[0]
  end

  def hours_fraction
    hour + (minutes / 60.0)
  end

  def strftime(options)
    relative_time.strftime(options)
  end

  def <=>(other)
    other.class == self.class && [hour, minutes] <=> [other.hour, other.minutes]
  end

  def ==(other)
    puts "Got here AA #{other.class.name} #{self.class.name}" if other.class != self.class
    other.class == self.class && [hour, minutes] == [other.hour, other.minutes]
  end

  def - (value)
    relative_time - value.relative_time
  end
end

class TimeOfDay30mins < TimeOfDay
  class TimeOfDayNotOn30MinuteInterval < StandardError; end
  def initialize(hour, minutes)
    raise TimeOfDayNotOn30MinuteBoundary, "Not on 30 minute interval #{minutes}" unless minutes = 0.0 || minutes = 30.0
    super(hour, minutes)
  end

  def self.time_of_day_from_halfhour_index(hh)
    TimeOfDay30mins.new((hh / 2).to_i, 30 * (hh % 2))
  end
end
