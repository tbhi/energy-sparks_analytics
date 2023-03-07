# frozen_string_literal: true

require 'spec_helper'
require 'active_support/core_ext'

describe Benchmarking::BenchmarkContentChangeInGasBetweenLast2Holidays, type: :service do
  let(:benchmark) do
    Benchmarking::BenchmarkContentChangeInGasBetweenLast2Holidays.new(
      benchmark_database_hash,
      benchmark_database_hash.keys.first,
      :change_in_gas_holiday_consumption_previous_holiday,
      Benchmarking::BenchmarkManager::CHART_TABLE_CONFIG[:change_in_gas_holiday_consumption_previous_holiday]
    )
  end

  describe '#content_title' do
    it 'returns the content title' do
      html = benchmark.send(:content_title)
      expect(html).to match_html(<<~HTML)
        <h1>
          Change in gas use between the last 2 holidays
        </h1>
      HTML
      title_html = '<h1>' + I18n.t("analytics.benchmarking.chart_table_config.change_in_gas_holiday_consumption_previous_holiday") + '</h1>'
      expect(html).to match_html(title_html)
    end
  end
end
