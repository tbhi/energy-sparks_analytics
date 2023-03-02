# frozen_string_literal: true

require 'spec_helper'
require 'active_support/core_ext'

describe Benchmarking::BenchmarkHeatingComingOnTooEarly, type: :service do
  let(:benchmark) do
    Benchmarking::BenchmarkHeatingComingOnTooEarly.new(
      benchmark_database_hash,
      benchmark_database_hash.keys.first,
      :heating_coming_on_too_early,
      Benchmarking::BenchmarkManager::CHART_TABLE_CONFIG[:heating_coming_on_too_early]
    )
  end

  describe '#content_title' do
    it 'returns the content title' do
      html = benchmark.send(:content_title)
      expect(html).to match_html(<<~HTML)
        <h1>
          Heating start time
        </h1>
      HTML
      title_html = '<h1>' + I18n.t("analytics.benchmarking.chart_table_config.heating_coming_on_too_early") + '</h1>'
      expect(html).to match_html(title_html)
    end
  end
end