require 'digest'
require 'net/http'
require 'json'
require 'amazing_print'
require 'date'
require 'csv'

class SolarEdgeSolarPV
  def initialize(api_key = ENV['ENERGYSPARKSSOLAREDGEAPIKEY'])
    @api_key = api_key
  end

  def site_details
    @site_details ||= json_query(site_details_url)
  end

  def site_ids
    sites.map{ |site| site['id'] }
  end

  def sites
    site_details['sites']['site']
  end

  def site_start_end_dates(site_id)
    dates = json_query(meter_start_end_dates_url(site_id))
    [Date.parse(dates['dataPeriod']['startDate']), Date.parse(dates['dataPeriod']['endDate'])]
  end

  def print_site_details
    ap site_details
    ap site_ids
  end

  # nil date will find max and min dates, so nil, nil => all data
  def smart_meter_data(meter_id, start_date, end_date)
    start_date, end_date = set_dates(meter_id, start_date, end_date)

    raw_data =  raw_meter_readings(meter_id, start_date, end_date)

    processed_meter_data = select_wanted_data_and_convert_keys(raw_data)

    convert_to_meter_type_to_date_to_kwh_x48(processed_meter_data, start_date, end_date) 
  end

  def solar_pv_readings(meter_id, start_date, end_date)
    start_date, end_date = set_dates(meter_id, start_date, end_date)
    
    raw_data = raw_production_meter_readings(meter_id, start_date, end_date)

    dt_to_kwh = raw_data.map{ |h| [date(h['date']) , (h['value'] || 0.0) / 1000.0]}.to_h

    convert_to_date_to_kwh_x48(dt_to_kwh, start_date, end_date)
  end

  private

  def convert_to_date_to_kwh_x48(dt_to_kwh, start_date, end_date)
    missing_readings = []
    readings = Hash.new { |h, k| h[k] = Array.new(48, 0.0) }

    (start_date..end_date).each do |date|
      (0..23).each do |hour|
        [0, 30].each_with_index do |mins30, hh_index|
          [0, 15].each do |mins15|
            dt = datetime_to_15_minutes(date, hour, mins30 + mins15)
            if dt_to_kwh.key?(dt)
              readings[date][hour * 2 + hh_index] += dt_to_kwh[dt]
            else
              missing_readings.push(dt)
            end
          end
        end
      end
    end
    {
      readings:         readings,
      missing_readings: missing_readings
    }
  end

  def datetime_to_15_minutes(date, hour, mins)
    dt = DateTime.new(date.year, date.month, date.day, hour, mins, 0)
    t = dt.to_time + 0
    DateTime.new(t.year, t.month, t.day, t.hour, t.min, t.sec)
  end

  def date(date_string)
    DateTime.parse(date_string)
  end

  def convert_to_meter_type_to_date_to_kwh_x48(processed_meter_data, start_date, end_date)
    processed_meter_data.map do |meter_type, dt_to_kwh|
      [
        meter_type,
        convert_to_date_to_kwh_x48(dt_to_kwh, start_date, end_date)
      ]
    end.to_h
  end

  def raw_meter_readings(meter_id, start_date, end_date)
    data = {}
    (start_date..end_date).each_slice(28) do |twenty_eight_days| # api limit of 1 month
      raw_data = raw_meter_readings_28_days_max(meter_id, twenty_eight_days.first, twenty_eight_days.last)
      converted_data = convert_raw_meter_data(raw_data)
      converted_data.each do |solar_edge_key, values|
        data[solar_edge_key] ||= {}
        data[solar_edge_key].merge!(values)
      end
    end
    data
  end

  def raw_meter_readings_28_days_max(meter_id, start_date, end_date)
    json_query(raw_all_meters_data_url(meter_id, start_date, end_date))
  end

  def raw_production_meter_readings(meter_id, start_date, end_date)
    data = []
    (start_date..end_date).each_slice(28) do |twenty_eight_days| # api limit of 1 month
      data.push(raw_production_meter_readings_28_days_max(meter_id, twenty_eight_days.first, twenty_eight_days.last))
    end
    data.flatten
  end

  def raw_production_meter_readings_28_days_max(meter_id, start_date, end_date)
    json_query(raw_generation_meter_data_url(meter_id, start_date, end_date))['energy']['values']
  end

  def json_query(url)
    uri = URI(url)
    response = Net::HTTP.get(uri)
    JSON.parse(response)
  end

  def convert_raw_meter_data(raw_data)
    raw_data['energyDetails']['meters'].map do |meter|
      [
        meter['type'],
        process_raw_values(meter['values'])
      ]
    end.to_h
  end

  def solar_edge_meter_type_map
    {
      'Production'      => :solar_pv,
      'Consumption'     => :electricity,
      'SelfConsumption' => nil,
      'FeedIn'          => :exported_solar_pv,
      'Purchased'       => nil # seems to be 'Consumption' + 'SelfConsumption'
    }
  end

  def select_wanted_data_and_convert_keys(processed_data)
    wanted_keys = solar_edge_meter_type_map.select{ |k,v|!v.nil? }

    wanted_keys.map do |solar_edge_key, energy_sparks_key|
      [
        energy_sparks_key,
        processed_data[solar_edge_key]
      ]
    end.to_h
  end

  def process_raw_values(raw_values)
    raw_values.map{ |h| [date(h['date']) , (h['value'] || 0.0) / 1000.0]}.to_h
  end

  def site_details_url
    'https://monitoringapi.solaredge.com/sites/list?size=5&searchText=Lyon&sortProperty=name&sortOrder=ASC&api_key=' + @api_key
  end

  def meter_start_end_dates_url(meter_id)
    'https://monitoringapi.solaredge.com/site/' + meter_id.to_s + '/dataPeriod?api_key='  + @api_key
  end

  def raw_generation_meter_data_url(meter_id, start_date, end_date)
    'https://monitoringapi.solaredge.com/site/' + meter_id.to_s + '/energy?timeUnit=QUARTER_OF_AN_HOUR' +
    '&endDate=' + end_date.to_s + '&startDate=' + start_date.to_s + '&api_key='  + @api_key
  end

  def raw_all_meters_data_url(meter_id, start_date, end_date)
   # https://monitoringapi.solaredge.com/site/1508552/energyDetails?timeUnit=QUARTER_OF_AN_HOUR&&startTime=2020-11-10%2011:00:00&endTime=2020-11-10%2013:00:00&api_key=RLLJ
    'https://monitoringapi.solaredge.com/site/' + meter_id.to_s + '/energyDetails?timeUnit=QUARTER_OF_AN_HOUR' +
     '&startTime=' + solar_edge_url_time(start_date) + '&endTime=' + solar_edge_url_time(end_date + 1) +
     '&api_key='  + @api_key
  end

  def solar_edge_url_time(date)
    date.strftime('%Y-%m-%d%2000:00:00')
  end

  def set_dates(meter_id, start_date, end_date)
    sd, ed = site_start_end_dates(meter_id) if start_date.nil? || end_date.nil?
    start_date = sd if start_date.nil?
    end_date   = ed if end_date.nil?
    [start_date, end_date]
  end
end

def default_config
  {
    start_date:     Date.today - 5,
    end_date:       Date.today - 1,
    csv_filename:   'solartestfile.csv',
    api_key:        ENV['ENERGYSPARKSSOLAREDGEAPIKEY'],
    site_id:        1508552,
    site_details:   false,
    mpan:           123456789
  }
end

def parse_command_line(config)
  args = ARGV.clone
  while !args.empty?
    if args[0] == '-startdate' && args.length >= 2
      config[:start_date] = Date.parse(args[1])
      args.shift(2)  
    elsif args[0] == '-enddate' && args.length >= 2
      config[:end_date] = Date.parse(args[1])
      args.shift(2)
    elsif args[0] == '-days' && args.length >= 2
      config[:start_date] = Date.today - args[1].to_i
      config[:end_date]   = Date.today - 1
      args.shift(2)
    elsif args[0] == '-csvfilename' && args.length >= 2
      config[:csv_filename] = args[1]
      args.shift(2)
    elsif args[0] == '-apikey' && args.length >= 2
      config[:api_key] = args[1]
      args.shift(2)
    elsif args[0] == '-mpan' && args.length >= 2
      config[:mpan] = args[1].to_i
      args.shift(2)
    elsif args[0] == '-siteid' && args.length >= 2
      config[:site_id] = args[1]
      args.shift(2)
    elsif args[0] == '-alldays'
      config[:start_date] = nil
      config[:end_date]   = nil
      args.shift(1)
    elsif args[0] == '-printsitedetails'
      config[:site_details] = true
      args.shift(1)
    else
      puts "Unexpected arguments #{args[0]}"
      puts "Arguments: -startdate <date> || -enddate <date> || -alldates "
      puts "        || -apikey <key> || -mpan <mpanroot>"
      puts "        || -siteid <key> || -printsitedetails || -days <N days data>"
      puts "provided arguments:"
      ap ARGV
      break
    end
  end
  config
end

def energy_sparks_solar_mpan(meter_type, mpan)
  case meter_type
  when :electricity
    90000000000000 + mpan
  when :solar_pv
    70000000000000 + mpan
  when :exported_solar_pv
    60000000000000 + mpan
  end
end

def save_readings_to_csv(readings, filename, mpan)
  puts "Saving readings to #{filename}"
  CSV.open(filename, 'w') do |csv|
    csv << ['date', 'mpan', 'meter type', 'days kWh', (0..47).map{ |hh| "#{(hh / 2).to_i}:#{(hh % 2) * 30}"}].flatten
    readings.each do |meter_type, data|
      data[:readings].each do |date, kwh_x48|
        es_mpan = energy_sparks_solar_mpan(meter_type, mpan)
        csv << [date, es_mpan, meter_type, kwh_x48.sum, kwh_x48].flatten
      end
    end
  end
end

config = parse_command_line(default_config)

solar_edge = SolarEdgeSolarPV.new(config[:api_key])

solar_edge.print_site_details if config[:site_details]

readings = solar_edge.smart_meter_data(config[:site_id], config[:start_date], config[:end_date])

save_readings_to_csv(readings, config[:csv_filename], config[:mpan])

puts "Missing readings:"
readings.values.each do |data|
  ap data[:missing_readings] unless data[:missing_readings].empty?
end
