# frozen_string_literal: true

require 'spec_helper'
require 'active_support/core_ext'

describe Benchmarking::BenchmarkSeasonalBaseloadVariation, type: :service do
  let(:benchmark) do
    Benchmarking::BenchmarkSeasonalBaseloadVariation.new(
      benchmark_database_hash,
      benchmark_database_hash.keys.first,
      :seasonal_baseload_variation,
      Benchmarking::BenchmarkManager::CHART_TABLE_CONFIG[:seasonal_baseload_variation]
    )
  end

  describe '#page' do
    it 'returns a chart name if charts are present' do
      expect(benchmark.page_name).to eq(:seasonal_baseload_variation)
    end
  end

  describe '#content_title' do
    it 'returns the content title' do
      html = benchmark.send(:content_title)
      expect(html).to match_html(<<~HTML)
        <h1>
          Seasonal baseload variation
        </h1>
      HTML
      title_html = '<h1>' + I18n.t("analytics.benchmarking.chart_table_config.seasonal_baseload_variation") + '</h1>'
      expect(html).to match_html(title_html)
    end
  end


  describe 'introduction_text' do
    it 'formats introduction and any caveat text as html' do
      html = benchmark.send(:introduction_text)
      expect(html).to match_html(<<~HTML)
        <p>
          A school's baseload is the electricity consumed by appliances kept running at all times.
        </p>
        <p>
          In general, the baseload in the winter should be very similar to the summer. In practice many schools leave electric heaters on overnight when the school is unoccupied. Identifying and turning off or better timing such equipment is a quick way of saving electricity and costs.
        </p>
        <p>
          This breakdown excludes electricity consumed by storage heaters and solar PV.
        </p>
      HTML
      content_html = I18n.t('analytics.benchmarking.content.seasonal_baseload_variation.introduction_text_html')
      content_html += I18n.t('analytics.benchmarking.caveat_text.es_exclude_storage_heaters_and_solar_pv')
      expect(html).to match_html(content_html)
    end
  end

  describe '#table_interpretation_text' do
    it 'formats table interpretation text as html' do
      html = benchmark.send(:table_interpretation_text)
      expect(html).to match_html(<<~HTML)
      HTML
    end
  end

  describe '#caveat_text' do
    it 'formats caveat text as html' do
      html = benchmark.send(:caveat_text)
      expect(html).to match_html(<<~HTML)
      HTML
    end
  end

  describe '#charts?' do
    it 'returns if charts are present' do
      expect(benchmark.send(:charts?)).to eq(true)
    end
  end

  describe '#chart_name' do
    it 'returns a chart name if charts are present' do
      expect(benchmark.send(:chart_name)).to eq(:seasonal_baseload_variation)
    end
  end

  describe '#tables?' do
    it 'returns if tables are present' do
      expect(benchmark.send(:tables?)).to eq(true)
    end
  end

  describe '#column_heading_explanation' do
    it 'returns the benchmark column_heading_explanation' do
      html = benchmark.column_heading_explanation([795], nil, nil)
      expect(html).to match_html(<<~HTML)
      HTML
    end
  end
end
