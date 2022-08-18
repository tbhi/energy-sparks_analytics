require 'spec_helper'

describe FormatEnergyUnit do

  let!(:value)   { 113.66216439927433 }

  context "ks2 formatting" do
    [
      { units: :£_0dp, expected: "&pound;114", medium: :html, type: String },
      { units: :£_0dp, expected: "£114",       medium: :text, type: String },
      { units: :£,     expected: "&pound;110", medium: :html, type: String },
      { units: :£,     expected: 113.66216439927433, medium: :raw,  type: Float }
    ].each do |config|
      it "formats value as #{config[:units]} to #{config[:medium]} as expected" do
        result = FormatEnergyUnit.format(config[:units], value, config[:medium])
        expect(result).to eq config[:expected]
        expect(result.class).to eq config[:type]
      end
    end
  end

  context "benchmark formatting" do
    [
      { units: :£_0dp, expected: "&pound;114", medium: :html, type: String },
      { units: :£_0dp, expected: "£114",       medium: :text, type: String },
      { units: :£,     expected: "&pound;114", medium: :html, type: String },
      { units: :£,     expected: 113.66216439927433, medium: :raw,  type: Float }
    ].each do |config|
      it "formats value as #{config[:units]} to #{config[:medium]} as expected" do
        result = FormatEnergyUnit.format(config[:units], value, config[:medium], false, false, :benchmark)
        expect(result).to eq config[:expected]
        expect(result.class).to eq config[:type]
      end
    end
  end

  context "energy expert formatting" do
    [
      { units: :£_0dp, expected: "&pound;114", medium: :html, type: String },
      { units: :£_0dp, expected: "£114",       medium: :text, type: String },
      { units: :£,     expected: "&pound;113.6621644", medium: :html, type: String },
      { units: :£,     expected: 113.66216439927433, medium: :raw,  type: Float }
    ].each do |config|
      it "formats value as #{config[:units]} to #{config[:medium]} as expected" do
        result = FormatEnergyUnit.format(config[:units], value, config[:medium], false, false, :energy_expert)
        expect(result).to eq config[:expected]
        expect(result.class).to eq config[:type]
      end
    end
  end

  context "'to pence' formatting" do
    [
      { units: :£_0dp, expected: "&pound;114", medium: :html, type: String },
      { units: :£_0dp, expected: "£114",       medium: :text, type: String },
      { units: :£,     expected: "&pound;113.66", medium: :html, type: String },
      { units: :£,     expected: 113.66216439927433, medium: :raw,  type: Float }
    ].each do |config|
      it "formats value as #{config[:units]} to #{config[:medium]} as expected" do
        result = FormatEnergyUnit.format(config[:units], value, config[:medium], false, false, :to_pence)
        expect(result).to eq config[:expected]
        expect(result.class).to eq config[:type]
      end
    end
  end

  context 'percentage formatting' do
    context ':percent' do
      it 'formats correctly' do
        expect(FormatUnit.format(:percent, 0.37019427511151964)).to eq("37%")
      end
    end
    context ':percent_0dp' do
      it 'formats correctly' do
        expect(FormatUnit.format(:percent_0dp, 0.37019427511151964)).to eq("37%")
      end
    end
    context ':relative_percent' do
      it 'formats correctly' do
       expect(FormatUnit.format(:relative_percent, -0.1188911792177762)).to eq("-12%")
       expect(FormatUnit.format(:relative_percent, 0.1188911792177762)).to eq("+12%")
      end
    end
    context ':relative_percent_0dp' do
      it 'formats correctly' do
       expect(FormatUnit.format(:relative_percent_0dp, -0.1188911792177762)).to eq("-12%")
       expect(FormatUnit.format(:relative_percent_0dp, 0.1188911792177762)).to eq("+12%")
      end
    end
    context ':comparison_percent' do
      it 'formats correctly' do
        expect(FormatUnit.format(:comparison_percent, 0.1)).to eq("+10%")
        expect(FormatUnit.format(:comparison_percent, -0.5)).to eq("-50%")
      end
    end
  end

  context 'date and time formatting' do
    context ':date' do
      it 'formats Dates' do
        date = Date.new(2000,1,1)
        expect(FormatEnergyUnit.format(:date, date, :text)).to eq "Saturday  1 Jan 2000"
      end
      it 'formats String as a date' do
        expect(FormatEnergyUnit.format(:date, "2000-01-01", :text)).to eq "Saturday  1 Jan 2000"
      end
    end
    context ':datetime' do
      it 'formats Date as a date time' do
        date = Date.new(2000,1,1)
        expect(FormatEnergyUnit.format(:datetime, date, :text)).to eq "Saturday  1 Jan 2000 00:00"
        date = DateTime.new(2000,1,1,14,40)
        expect(FormatEnergyUnit.format(:datetime, date, :text)).to eq "Saturday  1 Jan 2000 14:40"
      end
      it 'formats String as a date time' do
        expect(FormatEnergyUnit.format(:datetime, "2000-01-01", :text)).to eq "Saturday  1 Jan 2000 00:00"
      end
    end
    context ':date_mmm_yyyy' do
      it 'formats Dates' do
        date = Date.new(2000,1,1)
        expect(FormatEnergyUnit.format(:date_mmm_yyyy, date, :text)).to eq "Jan 2000"
      end
      it 'formats String as a date' do
        expect(FormatEnergyUnit.format(:date_mmm_yyyy, "2000-01-01", :text)).to eq "Jan 2000"
      end
    end
    context ':days' do
      it 'formats correctly' do
        expect(FormatUnit.format(:days, 1)).to eq "1 day"
        expect(FormatUnit.format(:days, 7)).to eq "7 days"
        expect(FormatUnit.format(:days, "1")).to eq "1 day"
        expect(FormatUnit.format(:days, "7")).to eq "7 days"
      end
    end
    context ':years' do
      it 'formats correctly'
    end
    context ':years_decimal' do
      it 'formats correctly' do
        expect(FormatUnit.format(:years_decimal, 2)).to eq "2 years"
      end
    end
    context ':years_range' do
      it 'formats correctly'
    end
    context ':timeofday' do
      it 'formats correctly' do
        expect(FormatEnergyUnit.format(:timeofday, "01:00")).to eq "01:00"
      end
    end
  end

  context '#format_time' do
    it 'formats correctly'
  end

  context 'money' do
    context ":£" do
      it "formats correctly"
    end
    context ":£_0dp" do
      it "formats correctly"
    end
    context ":£_per_kva" do
      it "formats correctly"
    end
    context ":£_per_kwh" do
      it "formats correctly"
    end
    context ":£_range" do
      it "formats correctly"
    end
  end

  context 'validating units' do
    it 'identifies known units' do
      expect(FormatUnit.known_unit?(:£)).to be true
      expect(FormatUnit.known_unit?(:kwh_per_day)).to be true
      expect(FormatUnit.known_unit?(:unknown)).to be false
    end
    it 'throws exception when units are unknown' do
      expect {
        FormatUnit.format(:unknown, 10, :text, false)
      }.to raise_exception EnergySparksUnexpectedStateException
    end
    it 'does not throw exception when not strict' do
      expect(FormatUnit.format(:unknown, 10, :text, true)).to eq("10")
    end
  end

  context '#percent_to_1_dp' do
    it 'returns expected results' do
      expect(FormatUnit.percent_to_1_dp(0.25, :text)).to eq("25.0%")
      expect(FormatUnit.percent_to_1_dp(0.25, :html)).to eq("25.0&percnt;")
    end
  end

  context 'temperature' do
    it 'formats correctly' do
      expect(FormatUnit.format(:temperature, 10)).to eq("10C")
      expect(FormatUnit.format(:temperature, 10.51)).to eq("10.5C")
    end
  end

  context 'r2' do
    it 'formats correctly' do
      expect(FormatUnit.format(:r2, 2)).to eq("2.00")
    end
  end

  context 'school names' do
    it 'formats correctly' do
      expect(FormatUnit.format(:school_name, "Junior School")).to eq("Junior School")
      expect(FormatUnit.format(:short_school_name, "Junior School")).to eq("Junior")
      expect(FormatUnit.format(:short_school_name, "Ysgol Draig")).to eq("Draig")
    end
  end

  context 'nil values' do
    it 'formats correctly'
  end

  context 'default formatting of other units' do
    it 'formats correctly' do
      expect(FormatUnit.format(:accounting_cost, 2)).to eq("£2")
      expect(FormatUnit.format(:bev_car, 2)).to eq("2 km")
      expect(FormatUnit.format(:boiler_start_time, 2)).to eq("2 boiler start time")
      expect(FormatUnit.format(:carnivore_dinner, 2)).to eq("2 dinners")
      expect(FormatUnit.format(:co2, 2)).to eq("2 kg CO2")
      expect(FormatUnit.format(:co2t, 2)).to eq("2 tonnes CO2")
      expect(FormatUnit.format(:co2t, 2)).to eq("2 tonnes CO2")
      expect(FormatUnit.format(:computer_console, 2)).to eq("2 computer consoles")
      expect(FormatUnit.format(:fuel_type, 2)).to eq("2")
      expect(FormatUnit.format(:home, 2)).to eq("2 homes")
      expect(FormatUnit.format(:homes_electricity, 2)).to eq("2 homes (electricity usage)")
      expect(FormatUnit.format(:homes_gas, 2)).to eq("2 homes (gas usage)")
      expect(FormatUnit.format(:hour, 2)).to eq("2 hours")
      expect(FormatUnit.format(:ice_car, 2)).to eq("2 km")
      expect(FormatUnit.format(:kettle, 2)).to eq("2 kettles")
      expect(FormatUnit.format(:kg, 2)).to eq("2 kg")
      expect(FormatUnit.format(:kg_co2_per_kwh, 2)).to eq("2 kg CO2/kWh")
      expect(FormatUnit.format(:km, 2)).to eq("2 km")
      expect(FormatUnit.format(:kva, 2)).to eq("2 kVA")
      expect(FormatUnit.format(:kw, 2)).to eq("2 kW")
      expect(FormatUnit.format(:kwh, 2)).to eq("2 kWh")
      expect(FormatUnit.format(:kwh_per_day, 2)).to eq("2 kWh/day")
      expect(FormatUnit.format(:kwh_per_day_per_c, 2)).to eq("2 kWh/day/C")
      expect(FormatUnit.format(:kwp, 2)).to eq("2 kWp")
      expect(FormatUnit.format(:library_books, 2)).to eq("2 library books")
      expect(FormatUnit.format(:litre, 2)).to eq("2 litres")
      expect(FormatUnit.format(:m2, 2)).to eq("2 m2")
      expect(FormatUnit.format(:m2, 2, :html)).to eq("2 m<sup>2</sup>")
      expect(FormatUnit.format(:meters, 2)).to eq("2 meters")
      expect(FormatUnit.format(:morning_start_time, 2)).to eq("2 time of day")
      expect(FormatUnit.format(:offshore_wind_turbine_hours, 2)).to eq("2 offshore wind turbine hours")
      expect(FormatUnit.format(:offshore_wind_turbines, 2)).to eq("2 offshore wind turbines")
      expect(FormatUnit.format(:onshore_wind_turbine_hours, 2)).to eq("2 onshore wind turbine hours")
      expect(FormatUnit.format(:onshore_wind_turbines, 2)).to eq("2 onshore wind turbines")
      expect(FormatUnit.format(:opt_start_standard_deviation, 2)).to eq("2 standard deviation (hours)")
      expect(FormatUnit.format(:optimum_start_sensitivity, 2)).to eq("2 hours/C")
      expect(FormatUnit.format(:panels, 2)).to eq("2 solar PV panels")
      expect(FormatUnit.format(:pupils, 2)).to eq("2 pupils")
      expect(FormatUnit.format(:shower, 2)).to eq("2 showers")
      expect(FormatUnit.format(:smartphone, 2)).to eq("2 smartphone charges")
      expect(FormatUnit.format(:solar_panels, 2)).to eq("2 solar panels")
      expect(FormatUnit.format(:solar_panels_in_a_year, 2)).to eq("2 solar panels in a year")
      expect(FormatUnit.format(:teaching_assistant, 2)).to eq("2 teaching assistant")
      expect(FormatUnit.format(:teaching_assistant_hours, 2)).to eq("2 teaching assistant (hours)")
      expect(FormatUnit.format(:tree, 2)).to eq("2 trees")
      expect(FormatUnit.format(:tv, 2)).to eq("2 tvs")
      expect(FormatUnit.format(:vegetarian_dinner, 2)).to eq("2 dinners")
      expect(FormatUnit.format(:w, 2)).to eq("2 W")
    end
  end
end
