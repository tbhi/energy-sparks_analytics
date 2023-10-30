require 'spec_helper'

describe Baseload::StatisticalBaseloadCalculator, type: :service do
  let(:start_date)      { Date.new(2023,1,1) }
  let(:end_date)        { Date.new(2023,1,2) }
  let(:kwh_data_x48)    { Array.new(48, 0.1) }
  let(:amr_data)        { build(:amr_data, :with_date_range, start_date: start_date, end_date: end_date, kwh_data_x48: kwh_data_x48) }

  subject(:calculator)  { Baseload::StatisticalBaseloadCalculator.new(amr_data) }

  context '#baseload_kw' do
    let(:day)             { start_date }
    let(:baseload_kw)     { calculator.baseload_kw(day) }

    it 'calculates the baseload for a day' do
      expect(baseload_kw).to be_within(0.0000001).of(0.2)
    end

    context 'with varied consumption' do
      #8 periods of 0.1, rest are random
      let(:kwh_data_x48)    { Array.new(10, rand(1.1..3.0)) + Array.new(4, 0.1) + Array.new(26, rand(1.1..3.0)) + Array.new(4, 0.1) + Array.new(4, rand(1.1..3.0)) }

      it 'calculates the baseload using lowest periods' do
        expect(baseload_kw).to be_within(0.0000001).of(0.2)
      end

      it 'does not sort original data' do
        baseload_kw
        expect(amr_data.days_kwh_x48(start_date)).to eq kwh_data_x48
      end
    end

    context 'for a day not in the data' do
      let(:day)  { Date.new(2023,4,1) }

      it 'raises an exception' do
        expect{ baseload_kw }.to raise_error(EnergySparksNotEnoughDataException)
      end
    end
  end
end