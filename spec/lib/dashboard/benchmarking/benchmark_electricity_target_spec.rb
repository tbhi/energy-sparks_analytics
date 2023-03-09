# frozen_string_literal: true

require 'spec_helper'
require 'active_support/core_ext'

describe Benchmarking::BenchmarkElectricityTarget, type: :service do
  let(:benchmark) do
    Benchmarking::BenchmarkElectricityTarget.new(
      benchmark_database_hash,
      benchmark_database_hash.keys.first,
      :electricity_targets,
      Benchmarking::BenchmarkManager::CHART_TABLE_CONFIG[:electricity_targets]
    )
  end

  describe '#page' do
    it 'returns a chart name if charts are present' do
      expect(benchmark.page_name).to eq(:electricity_targets)
    end
  end

  describe '#content_title' do
    it 'returns the content title' do
      html = benchmark.send(:content_title)
      expect(html).to match_html(<<~HTML)
        <h1>
          Progress against electricity target
        </h1>
      HTML
      title_html = '<h1>' + I18n.t("analytics.benchmarking.chart_table_config.electricity_targets") + '</h1>'
      expect(html).to match_html(title_html)
    end
  end

  describe 'introduction_text' do
    it 'formats introduction and any caveat text as html' do
      html = benchmark.send(:introduction_text)
      expect(html).to match_html(<<~HTML)
        <p>This benchmark shows how a school is progressing against the target it has set for this year.</p>
      HTML
      content_html = I18n.t('analytics.benchmarking.content.electricity_targets.introduction_text_html')
      expect(html).to match_html(content_html)
    end
  end

  describe '#chart_introduction_text' do
    it 'formats chart introduction text as html' do
      html = benchmark.send(:chart_introduction_text)
      expect(html).to match_html(<<~HTML)
      HTML
    end
  end

  describe '#chart_interpretation_text' do
    it 'formats chart interpretation text as html' do
      html = benchmark.send(:chart_interpretation_text)
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
      expect(benchmark.send(:chart_name)).to eq(:electricity_targets)
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
        <p>
          In school comparisons &apos;last year&apos; is defined as this year to date.
        </p>
      HTML
    end
  end
end