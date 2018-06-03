# boiler control: used by heating simulation model to describe the control
#                 features of a boiler
#
class BoilerControl
  attr_accessor :optimum_start, :frost_protection_temp
  attr_accessor :frost_protection_internal_temp
  attr_accessor :optimum_stop, :day_time_setback, :seven_day_control
  def initialize; end
end
