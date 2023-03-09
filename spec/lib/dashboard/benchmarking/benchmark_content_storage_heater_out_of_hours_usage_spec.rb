# frozen_string_literal: true

require 'spec_helper'
require 'active_support/core_ext'

describe Benchmarking::BenchmarkContentStorageHeaterOutOfHoursUsage, type: :service do
  let(:benchmark) do
    Benchmarking::BenchmarkContentStorageHeaterOutOfHoursUsage.new(
      benchmark_database_hash,
      benchmark_database_hash.keys.first,
      :annual_storage_heater_out_of_hours_use,
      Benchmarking::BenchmarkManager::CHART_TABLE_CONFIG[:annual_storage_heater_out_of_hours_use]
    )
  end

  describe '#page' do
    it 'returns a chart name if charts are present' do
      expect(benchmark.page_name).to eq(:annual_storage_heater_out_of_hours_use)
    end
  end

  describe '#content_title' do
    it 'returns the content title' do
      html = benchmark.send(:content_title)
      expect(html).to match_html(<<~HTML)
        <h1>
          Storage heaters used out of school hours
        </h1>
      HTML
      title_html = "<h1>#{I18n.t('analytics.benchmarking.chart_table_config.annual_storage_heater_out_of_hours_use')}</h1>"
      expect(html).to match_html(title_html)
    end
  end

  describe 'introduction_text' do
    it 'formats introduction and any caveat text as html' do
      html = benchmark.send(:introduction_text)
      expect(html).to match_html(<<~HTML)
        <p>Storage heaters consume electricity and store heat overnight when electricity is cheaper (assuming the school is on an 'economy 7' or differential tariff) and release the heat during the day.</p>
        <p>Ensuring heating is turned off over the weekend by installing a 7 day timer can provide a very short payback. Turning off the heaters or turning them down as low as possible to avoid frost damage can save during holidays.</p>
      HTML
      content_html = I18n.t('analytics.benchmarking.content.annual_storage_heater_out_of_hours_use.introduction_text_html')
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
      expect(benchmark.send(:chart_name)).to eq(:annual_storage_heater_out_of_hours_use)
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

  describe 'content' do
    it 'creates a content array' do
      content = benchmark.content(school_ids: [795, 629, 634], filter: nil)
      expect(content.class).to eq(Array)
      expect(content.size).to be > 0
    end
  end
end
