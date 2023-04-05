require 'spec_helper'

describe ChartManagerTimescaleManipulation do

  let(:operation_type)    { :move }

  let(:timescale)   { :up_to_a_year }

  let(:chart_config) {
    {
      :name=>"By Week: Electricity",
      :chart1_type=>:column,
      :chart1_subtype=>:stacked,
      :meter_definition=>:allelectricity,
      :x_axis=>:week,
      :series_breakdown=>:daytype,
      :yaxis_units=>:£,
      :yaxis_scaling=>:none,
      :timescale=>timescale,
      :community_use=>{:filter=>:all, :aggregate=>:community_use, :split_electricity_baseload=>true}
    }
  }

  let(:end_date)    { Date.today - 1 }
  let(:start_date)  { end_date - 365 }
  let(:amr_data)    { double('amr-data') }

  let(:electricity_aggregate_meter) { double('electricity-aggregated-meter')}
  let(:meter_collection)            { double('meter-collection') }

  before(:each) do
    allow(amr_data).to receive(:start_date).and_return(start_date)
    allow(amr_data).to receive(:end_date).and_return(end_date)
    allow(electricity_aggregate_meter).to receive(:amr_data).and_return(amr_data)
    allow(meter_collection).to receive(:aggregated_electricity_meters).and_return(electricity_aggregate_meter)
  end

  context '.factory' do
    %i[move extend contract compare].each do |operation|
      it "produces manipulator for #{operation}" do
        expect( ChartManagerTimescaleManipulation.factory(operation, chart_config, meter_collection) ).to_not be_nil
      end
    end
  end

  context 'ChartManagerTimescaleManipulationMove' do
    let(:manipulator) { ChartManagerTimescaleManipulationMove.new(operation_type, chart_config, meter_collection)}

    context '#adjust_timescale' do
      context 'with enough data' do
        let(:period)  { -1 }
        let(:expected_timescale)  { [{timescale => period}]}

        let(:start_date) { end_date - (365*3) }
        it 'updates timescale' do
          chart_config = manipulator.adjust_timescale(period)
          expect(chart_config[:timescale]).to eq expected_timescale
        end
      end

      context 'with not enough data' do
        it 'raises exception' do
          expect { manipulator.adjust_timescale(-1) }.to raise_error(EnergySparksNotEnoughDataException)
        end
      end
    end

    context '#can_go_back_in_time_one_period?' do
      context 'with enough data' do
        let(:start_date) { end_date - (365*3) }
        it 'returns true' do
          expect(manipulator.can_go_back_in_time_one_period?).to be true
        end
      end

      context 'with not enough data' do
        it 'returns false' do
          #default dates are a single year
          expect(manipulator.can_go_back_in_time_one_period?).to be false
        end
      end
    end

    context '#can_go_forward_in_time_one_period' do
      context 'with enough data' do
        let(:start_date) { Date.today - 365 }
        let(:end_date)   { Date.today + (365*2) }
        #cannot just move forward, need an existing period
        let(:timescale)   { [{up_to_a_year: -1}] }
        it 'returns true' do
          expect(manipulator.can_go_forward_in_time_one_period?).to be true
        end
      end

      context 'with not enough data' do
        it 'returns false' do
          #default dates are a single year
          expect(manipulator.can_go_forward_in_time_one_period?).to be false
        end
      end
    end

    context '#chart_suitable_for_timescale_manipulation?' do
      it 'returns true' do
        expect(manipulator.chart_suitable_for_timescale_manipulation?).to be true
      end
      context 'with no timescale value' do
        let(:timescale) { nil }
        it 'returns false' do
          expect(manipulator.chart_suitable_for_timescale_manipulation?).to be false
          chart_config.delete(:timescale)
          expect(manipulator.chart_suitable_for_timescale_manipulation?).to be false
        end
      end
    end

    context '#timescale_description' do
      it 'returns expected valid' do
        expect(manipulator.timescale_description).to eq 'year'
      end
    end
  end

end
