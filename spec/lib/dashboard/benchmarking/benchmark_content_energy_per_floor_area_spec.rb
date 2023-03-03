# frozen_string_literal: true

require 'spec_helper'
require 'active_support/core_ext'

describe Benchmarking::BenchmarkContentEnergyPerFloorArea, type: :service do
  let(:benchmark) do
    Benchmarking::BenchmarkContentEnergyPerFloorArea.new(
      benchmark_database_hash,
      benchmark_database_hash.keys.first,
      :annual_energy_costs_per_floor_area,
      Benchmarking::BenchmarkManager::CHART_TABLE_CONFIG[:annual_energy_costs_per_floor_area]
    )
  end

  describe '#content_title' do
    it 'returns the content title' do
      html = benchmark.send(:content_title)
      expect(html).to match_html(<<~HTML)
        <h1>
          Annual energy cost per floor area
        </h1>
      HTML
      title_html = '<h1>' + I18n.t("analytics.benchmarking.chart_table_config.annual_energy_costs_per_floor_area") + '</h1>'
      expect(html).to match_html(title_html)
    end
  end

  describe 'introduction_text' do
    it 'formats introduction and any caveat text as html' do
      html = benchmark.send(:introduction_text)
      expect(html).to match_html(<<~HTML)
        <p>
          <p>
            This benchmark is an alternative to the more commonly used per pupil energy benchmark.
          </p>
          <p>
            Generally, per pupil benchmarks are appropriate for electricity (as they should be proportional to the appliances
            in use), but per floor area benchmarks are more appropriate for gas (the size of building which needs heating).
            Overall, energy use comparison on a per pupil basis is probably more appropriate than on a per floor area basis, 
            but this analysis can be useful in some circumstances.
          </p>
        </p>
      HTML
      content_html = '<p>' + 
        I18n.t('analytics.benchmarking.content.annual_energy_costs_per_floor_area.introduction_text_html') +
        I18n.t('analytics.benchmarking.caveat_text.es_per_pupil_v_per_floor_area_useful_html') + '</p>'
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
      expect(benchmark.send(:chart_name)).to eq(:annual_energy_costs_per_floor_area)
    end
  end

  describe '#tables?' do
    it 'returns if tables are present' do
      expect(benchmark.send(:tables?)).to eq(true)
    end
  end
end
