# frozen_string_literal: true

require 'spec_helper'
require 'active_support/core_ext'

describe Benchmarking::BenchmarkContentHeatingPerFloorArea, type: :service do
  let(:benchmark) do
    described_class.new(
      benchmark_database_hash,
      benchmark_database_hash.keys.first,
      :annual_heating_costs_per_floor_area,
      Benchmarking::BenchmarkManager::CHART_TABLE_CONFIG[:annual_heating_costs_per_floor_area]
    )
  end

  describe '#page' do
    it 'returns a chart name if charts are present' do
      expect(benchmark.page_name).to eq(:annual_heating_costs_per_floor_area)
    end
  end

  describe '#content_title' do
    it 'returns the content title' do
      html = benchmark.send(:content_title)
      expect(html).to match_html(<<~HTML)
        <h1>
          Annual heating cost per floor area with savings potential
        </h1>
      HTML
      title_html = "<h1>#{I18n.t('analytics.benchmarking.chart_table_config.annual_heating_costs_per_floor_area')}</h1>"
      expect(html).to match_html(title_html)
    end
  end

  describe 'introduction_text' do
    it 'formats introduction and any caveat text as html' do
      html = benchmark.send(:introduction_text)

      expect(html).to match_html(<<~HTML)
        <p>This benchmark compares last year’s gas and storage heater costs per floor area (m2).</p>
        <p>The benchmark is adjusted for regional temperatures over the last year, so that for example schools in Scotland are compared on the same terms as schools in the warmer south west of England.</p>
        <p>For schools heated by gas, the cost includes gas used for hot water and by the school kitchen.</p>
        <p>Schools with negative savings potential  have heating consumption below that of the best schools, which is good. For schools with storage heaters, heating costs are calculated using electricity tariff prices including differential/economy-7 tariffs if schools are on such a tariff.</p>
      HTML
      content_html = I18n.t('analytics.benchmarking.content.annual_heating_costs_per_floor_area.introduction_text_html')
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

  describe '#table_introduction_text' do
    it 'formats table introduction text as html' do
      html = benchmark.send(:table_introduction_text)
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
      expect(benchmark.send(:chart_name)).to eq(:annual_heating_costs_per_floor_area)
    end
  end

  describe '#tables?' do
    it 'returns if tables are present' do
      expect(benchmark.send(:tables?)).to eq(true)
    end
  end

  describe '#column_heading_explanation' do
    it 'returns the benchmark column_heading_explanation' do
      html = benchmark.column_heading_explanation
      expect(html).to match_html(<<~HTML)
        <p>
          In school comparisons &apos;last year&apos; is defined as this year to date.
        </p>
      HTML
    end
  end

  describe 'footnote' do
    it 'returns footnote text' do
      content = benchmark.send(:footnote, [795, 629, 634], nil, {})
      expect(content).to match_html('')
    end
  end

  describe 'content' do
    it 'creates a content array' do
      content = benchmark.content(school_ids: [795, 629, 634], filter: nil)
      expect(content.class).to eq(Array)
      expect(content.size).to be > 0
    end

    it 'translates column_groups' do
      content = benchmark.content(school_ids: [795, 629, 634], filter: nil)
      column_groups = content.select do |c|
                        c[:type] == :table_composite
                      end.map { |c| c.dig(:content, :column_groups) }.compact
      expect(column_groups).to eq([])
    end
  end
end
