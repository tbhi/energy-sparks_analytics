require_relative '../app/models/meter_attributes'


describe MeterAttributes do

  describe MeterAttributeTypes::Symbol do
    it 'converts strings to symbols' do
      expect(MeterAttributeTypes::Symbol.new(allowed_values: [:weekends]).parse('weekends')).to eq(:weekends)
    end
    it 'converts non-strings to symbols' do
      expect(MeterAttributeTypes::Symbol.new(allowed_values: [:"0"]).parse(0)).to eq(:"0")
    end
    it 'leaves nils as nil' do
      expect(MeterAttributeTypes::Symbol.new(allowed_values: [:weekends]).parse(nil)).to eq(nil)
    end
    it 'leaves symbols as symbols' do
      expect(MeterAttributeTypes::Symbol.new(allowed_values: [:weekends]).parse(:weekends)).to eq(:weekends)
    end
    it 'raises and error on unknown values' do
      expect{
        MeterAttributeTypes::Symbol.new(allowed_values: [:weekends]).parse(:weekdays)
      }.to raise_error(MeterAttributeTypes::InvalidAttributeValue)
    end
    it 'raises no error if no allowed values are set' do
      expect{
        MeterAttributeTypes::Symbol.new.parse(:weekdays)
      }.to_not raise_error
    end
  end

  describe MeterAttributeTypes::Integer do
    it 'converts strings to integers' do
      expect(MeterAttributeTypes::Integer.new.parse('0')).to eq(0)
    end
    it 'leaves nils as nil' do
      expect(MeterAttributeTypes::Integer.new().parse(nil)).to eq(nil)
    end
    it 'leaves integers as integers' do
      expect(MeterAttributeTypes::Integer.new().parse(1)).to eq(1)
    end
    it 'raises and error on unknown values'
  end

  describe MeterAttributeTypes::Float do
    it 'converts strings to floats' do
      expect(MeterAttributeTypes::Float.new.parse('1.0')).to eq(1.0)
    end
    it 'leaves nils as nil' do
      expect(MeterAttributeTypes::Float.new().parse(nil)).to eq(nil)
    end
    it 'leaves floats  as floats ' do
      expect(MeterAttributeTypes::Float.new().parse(1.0)).to eq(1.0)
    end
    it 'converts integers to floats' do
      expect(MeterAttributeTypes::Float.new().parse(1)).to eq(1.0)
    end
  end

  describe MeterAttributeTypes::Hash do
    it 'parses sub-values' do
      expect(MeterAttributeTypes::Hash.new(structure: {day_of_week: MeterAttributeTypes::Integer.define}).parse({day_of_week: '0'})).to eq({day_of_week: 0})
    end
    it 'returns nil if all the values are empty and the field is not required' do
      expect(MeterAttributeTypes::Hash.new(structure: {day_of_week: MeterAttributeTypes::Integer.define}).parse({day_of_week: nil})).to eq(nil)
    end
    it 'returns an empty hash id all the values are empty and the field is required' do
      expect(MeterAttributeTypes::Hash.new(structure: {day_of_week: MeterAttributeTypes::Integer.define}, required: true).parse({day_of_week: nil})).to eq({})
    end
    it 'strips out nil values' do
      expect(MeterAttributeTypes::Hash.new(structure: {day_of_week: MeterAttributeTypes::Integer.define, month_of_year: MeterAttributeTypes::Integer.define}).parse({day_of_week: 1})).to eq({day_of_week: 1})
    end
    it 'leaves nils as nils' do
      expect(MeterAttributeTypes::Hash.new().parse(nil)).to eq(nil)
    end
  end

  describe MeterAttributeTypes::TimeOfYear do
    it 'parses a hash of values' do
      expect(MeterAttributeTypes::TimeOfYear.new.parse({month: 1, day_of_month: 12})).to eq(TimeOfYear.new(1, 12))
    end

    it 'converts strings to integers' do
      expect(MeterAttributeTypes::TimeOfYear.new.parse({month: '1', day_of_month: '12'})).to eq(TimeOfYear.new(1, 12))
    end

    it 'returns nil with missing values' do
      expect(MeterAttributeTypes::TimeOfYear.new.parse({day_of_month: '12'})).to eq(nil)
      expect(MeterAttributeTypes::TimeOfYear.new.parse({month: '12'})).to eq(nil)
    end

  end

  describe MeterAttributeTypes::TimeOfDay do
    it 'parses a hash of values' do
      expect(MeterAttributeTypes::TimeOfDay.new.parse({hour: 1, minutes: 12})).to eq(TimeOfDay.new(1, 12))
    end

    it 'converts strings to integers' do
      expect(MeterAttributeTypes::TimeOfDay.new.parse({hour: '1', minutes: '12'})).to eq(TimeOfDay.new(1, 12))
    end

    it 'returns nil with missing values' do
      expect(MeterAttributeTypes::TimeOfDay.new.parse({minutes: '12'})).to eq(nil)
      expect(MeterAttributeTypes::TimeOfDay.new.parse({hours: '12'})).to eq(nil)
    end
  end

  describe MeterAttributeTypes::Date do
    it 'parses a string' do
      expect(MeterAttributeTypes::Date.new.parse('3/1/2012')).to eq(Date.new(2012, 1, 3))
    end

    it 'raises and error on unknown values'
  end

  describe MeterAttributeTypes::Boolean do
    it 'handles truthy values' do
      expect(MeterAttributeTypes::Boolean.new.parse('true')).to eq(true)
      expect(MeterAttributeTypes::Boolean.new.parse(true)).to eq(true)
      expect(MeterAttributeTypes::Boolean.new.parse(1)).to eq(true)
      expect(MeterAttributeTypes::Boolean.new.parse('1')).to eq(true)
    end

    it 'handles falsey' do
      expect(MeterAttributeTypes::Boolean.new.parse('false')).to eq(nil)
      expect(MeterAttributeTypes::Boolean.new.parse(false)).to eq(nil)
      expect(MeterAttributeTypes::Boolean.new.parse(0)).to eq(nil)
      expect(MeterAttributeTypes::Boolean.new.parse('0')).to eq(nil)
    end

  end

  describe MeterAttributes::AutoInsertMissingReadings do
    it 'accepts a hash as input and keys it using the class defined key' do
      attribute = MeterAttributes::AutoInsertMissingReadings.parse({type: :weekends})
      expect(attribute.to_analytics).to eq(
        {auto_insert_missing_readings: {type: :weekends}}
      )
    end

    it 'parses string values and converts them to symbols' do
      attribute = MeterAttributes::AutoInsertMissingReadings.parse({type: 'weekends'})
      expect(attribute.to_analytics).to eq(
        {auto_insert_missing_readings: {type: :weekends}}
      )
    end
  end

  describe MeterAttributes::AutoInsertMissingReadings do
    it 'accepts a hash of time of year and keys it using the class defined key' do
      attribute = MeterAttributes::NoHeatingInSummerSetMissingToZero.parse({start_toy: {month: 3, day_of_month: 23}, end_toy: {month: 12, day_of_month: 1}})
      expect(attribute.to_analytics).to eq(
        {no_heating_in_summer_set_missing_to_zero: {start_toy: TimeOfYear.new(3, 23), end_toy: TimeOfYear.new(12, 1)}}
      )
    end
  end

  describe MeterAttributes::RescaleAmrData do
    it 'accepts a hash of dates and floats and keys it using the class defined key' do
      attribute = MeterAttributes::RescaleAmrData.parse({start_date: '13/1/2012', end_date: '12/1/2013', scale: '12.0'})
      expect(attribute.to_analytics).to eq(
        {rescale_amr_data: {start_date: Date.new(2012, 1, 13), end_date: Date.new(2013, 1, 12), scale: 12.0}}
      )
    end
  end

  describe MeterAttributes::SetMissingDataToZero do
    it 'accepts a hash of dates and keys it using the class defined key' do
      attribute = MeterAttributes::SetMissingDataToZero.parse({start_date: '13/1/2012', end_date: '12/1/2013'})
      expect(attribute.to_analytics).to eq(
        {set_missing_data_to_zero: {start_date: Date.new(2012, 1, 13), end_date: Date.new(2013, 1, 12)}}
      )
    end
  end

  describe MeterAttributes::SetBadDataToZero do
    it 'accepts a hash of dates and keys it using the class defined key' do
      attribute = MeterAttributes::SetBadDataToZero.parse({start_date: '13/1/2012', end_date: '12/1/2013'})
      expect(attribute.to_analytics).to eq(
        {set_bad_data_to_zero: {start_date: Date.new(2012, 1, 13), end_date: Date.new(2013, 1, 12)}}
      )
    end
  end

  describe MeterAttributes::OverrideBadReadings do
    it 'accepts a hash of dates and keys it using the class defined key' do
      attribute = MeterAttributes::OverrideBadReadings.parse({start_date: '13/1/2012', end_date: '12/1/2013'})
      expect(attribute.to_analytics).to eq(
        {override_bad_readings: {start_date: Date.new(2012, 1, 13), end_date: Date.new(2013, 1, 12)}}
      )
    end
  end

  describe MeterAttributes::ExtendMeterReadingsForSubstitution do
    it 'accepts a hash of dates and keys it using the class defined key' do
      attribute = MeterAttributes::ExtendMeterReadingsForSubstitution.parse({start_date: '13/1/2012', end_date: '12/1/2013'})
      expect(attribute.to_analytics).to eq(
        {extend_meter_readings_for_substitution: {start_date: Date.new(2012, 1, 13), end_date: Date.new(2013, 1, 12)}}
      )
    end
  end

  describe MeterAttributes::ReadingsStartDate do
    it 'accepts a single date and keys it using the class defined key' do
      attribute = MeterAttributes::ReadingsStartDate.parse('13/1/2012')
      expect(attribute.to_analytics).to eq(
        {readings_start_date: Date.new(2012, 1, 13)}
      )
    end
  end

  describe MeterAttributes::MeterCorrectionSwitch do
    it 'accepts a string or symbol and keys it using the class defined key' do
      attribute = MeterAttributes::MeterCorrectionSwitch.parse('set_all_missing_to_zero')
      expect(attribute.to_analytics).to eq(
        :set_all_missing_to_zero
      )
    end
  end

  describe MeterAttributes::HeatingModel do
    it 'accepts nested attributes and them it using the class defined key' do
      attribute = MeterAttributes::HeatingModel.parse(
        max_summer_daily_heating_kwh: '200',
        fitting: {
          fit_model_start_date: '12/3/2017',
          fit_model_end_date: '13/4/2018',
          expiry_date_of_override: '12/5/2019',
          use_dates_for_model_validation: 'true'
        }
      )
      expect(attribute.to_analytics).to eq({
        heating_model: {
          max_summer_daily_heating_kwh: 200,
          fitting: {
            fit_model_start_date: Date.new(2017, 3, 12),
            fit_model_end_date: Date.new(2018, 4, 13),
            expiry_date_of_override: Date.new(2019, 5, 12),
            use_dates_for_model_validation: true
          }
        }
      })
    end
  end

  describe MeterAttributes::AggregationSwitch do
    it 'accepts a string or symbol and keys it using the class defined key' do
      attribute = MeterAttributes::AggregationSwitch.parse('ignore_start_date')
      expect(attribute.to_analytics).to eq(
        :ignore_start_date
      )
    end
  end

  describe MeterAttributes::FunctionSwitch do
    it 'accepts a string or symbol and keys it using the class defined key' do
      attribute = MeterAttributes::FunctionSwitch.parse('heating_only')
      expect(attribute.to_analytics).to eq(
        :heating_only
      )
    end
  end

  describe MeterAttributes::Tariff do
    it 'accepts a string or symbol and keys it using the class defined key' do
      attribute = MeterAttributes::Tariff.parse({type: 'economy_7'})
      expect(attribute.to_analytics).to eq(
        {tariff: {type: :economy_7}}
      )
    end
  end

  describe MeterAttributes::SolarPV do
    it 'accepts a hash and parses the values and keys it using the class definition' do
      attribute = MeterAttributes::SolarPV.parse({
        start_date:         '1/1/2017',
        end_date:           '2/2/2017',
        kwp:                '30.0',
        orientation:        '1',
        tilt:               '180',
        shading:            30,
        fit_£_per_kwh:      '20.0'
      })
      expect(attribute.to_analytics).to eq(
        {
          start_date:         Date.new(2017, 1, 1),
          end_date:           Date.new(2017, 2, 2),
          kwp:                30.0,
          orientation:        1,
          tilt:               180,
          shading:            30,
          fit_£_per_kwh:      20.0
        }
      )
    end
  end

  describe MeterAttributes::SolarPVOverrides do
    it 'accepts a hash and parses the values and keys it using the class definition' do
      attribute = MeterAttributes::SolarPVOverrides.parse({
        start_date:         '1/1/2017',
        end_date:           '2/2/2017',
        kwp:                '30.0',
        orientation:        '1',
        tilt:               '180',
        shading:            30,
        fit_£_per_kwh:      '20.0',
        override_generation:    'true',
        override_export:        'true',
        override_self_consume:  'true'
      })
      expect(attribute.to_analytics).to eq(
        {
          start_date:         Date.new(2017, 1, 1),
          end_date:           Date.new(2017, 2, 2),
          kwp:                30.0,
          orientation:        1,
          tilt:               180,
          shading:            30,
          fit_£_per_kwh:      20.0,
          override_generation:    true,
          override_export:        true,
          override_self_consume:  true
        }
      )
    end
  end

  describe MeterAttributes::SolarPVMeterMapping do
    it 'accepts a hash and parses the values and keys it using the class definition' do
      attribute = MeterAttributes::SolarPVMeterMapping.parse({
        start_date:         '1/1/2017',
        end_date:           '2/2/2017',
        export_mpan:        '123456',
        production_mpan:    '123457',
        self_consume_mpan:  '123458'
      })
      expect(attribute.to_analytics).to eq(
        {
          start_date:         Date.new(2017, 1, 1),
          end_date:           Date.new(2017, 2, 2),
          export_mpan:        '123456',
          production_mpan:    '123457',
          self_consume_mpan:  '123458'
        }
      )
    end
  end

  class SolarPVMeterMapping < MeterAttributeTypes::AttributeBase

    id                  :solar_pv_mpan_meter_mapping
    aggregate_over      :solar_pv_mpan_meter_mapping
    name                'Solar PV MPAN Meter mapping'

    structure MeterAttributeTypes::Hash.define(
      structure: {
        start_date:         MeterAttributeTypes::Date.define(required: true),
        end_date:           MeterAttributeTypes::Date.define,
        export_mpan:        MeterAttributeTypes::String.define,
        production_mpan:    MeterAttributeTypes::String.define,
        self_consume_mpan:  MeterAttributeTypes::String.define
      }
    )
  end

  describe MeterAttributes::LowCarbonHub do
    it 'accepts a string or symbol and keys it using the class defined key' do
      attribute = MeterAttributes::LowCarbonHub.parse('2345')
      expect(attribute.to_analytics).to eq(
        {low_carbon_hub_meter_id: 2345}
      )
    end
  end

  describe MeterAttributes::StorageHeaters do
    it 'accepts a hash and parses the values and keys it using the class definition' do
      attribute = MeterAttributes::StorageHeaters.parse({
        start_date:         '1/1/2017',
        end_date:           '2/2/2017',
        power_kw:           '30.0',
        charge_start_time:   {hour: 23, minutes: 12},
        charge_end_time:     {hour: 23, minutes: 15}
      })
      expect(attribute.to_analytics).to eq(
        {
          start_date: Date.new(2017, 1, 1),
          end_date:   Date.new(2017, 2, 2),
          power_kw:   30.0,
          charge_start_time: TimeOfDay.new(23,12),
          charge_end_time: TimeOfDay.new(23,15)
        }
      )
    end
  end
end
