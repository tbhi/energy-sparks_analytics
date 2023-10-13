# frozen_string_literal: true
require 'spec_helper'

describe SolarPhotovoltaics::ExistingBenefitsService, type: :service do
  let(:service) { SolarPhotovoltaics::ExistingBenefitsService.new(meter_collection: @acme_academy) }

  # using before(:all) here to avoid slow loading of YAML and then
  # running the aggregation code for each test.
  before(:all) do
    @acme_academy = load_unvalidated_meter_collection(school: 'acme-academy-with-solar')
  end

  context '#enough_data?' do
    it 'returns true if one years worth of data is available' do
      expect(service.enough_data?).to eq(true)
    end
  end

  context '#create_model' do
    let(:benefits)  { service.create_model }

    it 'calculates the existing benefits for a school with solar pv' do
      expect(benefits.annual_saving_from_solar_pv_percent).to be_within(0.01).of(0.177)
      expect(benefits.annual_electricity_including_onsite_solar_pv_consumption_kwh).to be_within(0.01).of(60911.12)
      expect(benefits.annual_carbon_saving_percent).to be_within(0.01).of(0.21)
      expect(benefits.saving_£current).to be_within(0.01).of(4540.36)
      expect(benefits.export_£).to be_within(0.01).of(77.80)
      expect(benefits.annual_co2_saving_kg).to be_within(0.01).of(1935.25)

      # summary table of electricity usage for the last year
      expect(benefits.annual_solar_pv_kwh).to be_within(0.01).of(12959.86)
      expect(benefits.annual_exported_solar_pv_kwh).to be_within(0.01).of(1556.18)
      expect(benefits.annual_solar_pv_consumed_onsite_kwh).to be_within(0.01).of(10819.92)
      expect(benefits.annual_consumed_from_national_grid_kwh).to be_within(0.01).of(50091.2)
    end
  end
end
