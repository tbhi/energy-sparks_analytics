module AlertModelCacheMixin
  # during analytics testing store model results to save recalculating for different alerts at same school
  private def model_cache(urn, asof_date)
    return call_model(asof_date) unless AlertAnalysisBase.test_mode
    @@model_cache_results ||= {}
    composite_key = urn.to_s + ':' + asof_date.to_s
    return @@model_cache_results[composite_key] if @@model_cache_results.key?(composite_key)
    @@model_cache_results.delete(@@model_cache_results.keys.first) if @@model_cache_results.length > 10 # limit cache size else memory leak
    @@model_cache_results[composite_key] = call_model(asof_date)
  end

  protected def asof_date_minus_one_year(date)
    date - 364
  end

  protected def model_start_date(asof_date)
    asof_date_minus_one_year(asof_date)
  end

  protected def one_year_period(asof_date)
    SchoolDatePeriod.new(:alert, 'Current Year', model_start_date(asof_date), asof_date)
  end

  protected def enough_data_for_model_fit
    @heating_model = calculate_model(asof_date) if @heating_model.nil?
    @heating_model.enough_samples_for_good_fit
  end

  private def call_model(asof_date)
    aggregate_meter.model_cache.create_and_fit_model(:best, one_year_period(asof_date)) 
  end
end
