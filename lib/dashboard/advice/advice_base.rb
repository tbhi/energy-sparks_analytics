require_rel '../charting_and_reports/content_base.rb'
class AdviceBase < ContentBase
  include Logging
  attr_reader :summary
  def initialize(school)
    super(school)
    @failed_charts = []
  end

  def enough_data
    :enough
  end

  def valid_alert?
    true
  end

  def analyse(asof_date)
    @asof_date = asof_date
    calculate
  end

  def failed_charts
    @failed_charts
  end

  def calculate
    @rating = nil
    promote_data if self.class.config.key?(:promoted_variables)
  end

  # override alerts base class
  def make_available_to_users?
    make_available = relevance == :relevant && enough_data == :enough && @calculation_worked #  && failed_charts_required.empty?
    unless make_available
      message = "Analysis #{self.class.name} not being made available to users: reason: #{relevance} #{enough_data} calc: #{@calculation_worked} failed charts #{@failed_charts.length}"
      logger.info message
    end
    make_available
  end

  def failed_charts_required
    @failed_charts.select{ |failed_chart| !charts_that_are_allowed_to_fail.include?(failed_chart[:chart_name])}
  end

  def charts_that_are_allowed_to_fail
    self.class.config.nil? ? [] : self.class.config.fetch(:skip_chart_and_advice_if_fails, [])
  end

  def tolerate_chart_failure(chart_name)
    charts_that_are_allowed_to_fail.include?(chart_name)
  end

  def rating
    @rating
  end

  def relevance
    :relevant
  end

  def chart_names
    self.class.config[:charts]
  end

  def charts
    chart_results = []

    chart_names.each do |chart_name|
      chart_results.push(run_chart(chart_name))
    end
    chart_results
  end

  def front_end_content(user_type: nil)
    content(user_type: user_type).select { |segment| %i[html chart_name enhanced_title].include?(segment[:type]) }
  end

  def debug_content
    [
      { type: :analytics_html, content: "<h2>#{self.class.config[:name]}</h2>" },
      { type: :analytics_html, content: "<h3>Rating: #{rating}</h3>" },
      { type: :analytics_html, content: "<h3>Valid: #{valid_alert?}</h3>" },
      { type: :analytics_html, content: "<h3>Make available to users: #{make_available_to_users?}</h3>" },
      { type: :analytics_html, content: template_data_html }
    ]
  end

  def content(user_type: nil)
    rsc = raw_structured_content(user_type: user_type)
    content_info = rsc.length == 1 ? rsc[0][:content] : flatten_structured_content(rsc)
    remove_diagnostics_from_html(content_info, user_type)
  end

  def has_structured_content?(user_type: nil)
    structured_meter_breakdown?(user_type) &&
    self.class.config[:meter_breakdown][:presentation_style] == :structured
  end

  def structured_content(user_type: nil)
    raw_structured_content(user_type: user_type)
  end

  def analytics_split_charts_and_html(content_data)
    html_bits = content_data.select { |h| %i[html analytics_html].include?(h[:type]) }
    html = html_bits.map { |v| v[:content] }
    charts_bits = content_data.select { |h| h[:type] == :chart }
    charts = charts_bits.map { |v| v[:content] }
    [html, charts]
  end

  def self.config
    definition
  end

  def self.excel_worksheet_name
    definition[:excel_worksheet_name]
  end

  def erb_bind(text)
    ERB.new(text).result(binding)
  end

  # used by analytics - inserts location of chart, but real chart goes to Excel
  def self.highlighted_dummy_chart_name_html(chart_name)
    text = %{
      <div style="background-color: #cfc ; padding: 10px; border: 1px solid green;">
        <h3>Chart: <%= chart_name %></h3>
      </div>
    }
    ERB.new(text).result(binding)
  end

  def self.template_variables
    { 'Summary' => promote_variables }
  end

  def self.promote_variables
    template_variables = {}
    self.config[:promoted_variables].each do |alert_class, variables|
      variables.each do |to, from|
        template_variables[to] = find_alert_variable_definition(alert_class.template_variables, from)
      end
    end
    template_variables
  end

  def self.find_alert_variable_definition(variable_groups, find_variable_name)
    variable_groups.each do |_group_name, variable_group|
      return variable_group[find_variable_name] if variable_group.key?(find_variable_name)
    end
  end

  protected

  def remove_diagnostics_from_html(charts_and_html, user_type)
    if ContentBase.analytics_user?(user_type)
      charts_and_html = promote_analytics_html_to_frontend(charts_and_html)
    else
      charts_and_html.delete_if { |content_component| %i[analytics_html].include?(content_component[:type]) }
    end
    charts_and_html
  end

  def remove_diagnostics_from_content(content, user_type)
    {
      title:    content[:title],
      content:  remove_diagnostics_from_html(content[:content], user_type)
    }
  end

  def remove_diagnostics_from_structured_content(structured_content, user_type)
    structured_content.map { |c| remove_diagnostics_from_content(c, user_type) }
  end

  private

  def raw_structured_content(user_type: nil)
    base = [
      {
        title:    'All school meters aggregated:',
        content:  raw_content(user_type: user_type)
      }
    ]

    base += underlying_meters_structured_content(user_type: user_type) if structured_meter_breakdown?(user_type)

    base
  end

  def flatten_structured_content(sc_content)
    sc_content.map do |component|
      [
        { type: :html, content: component[:html_title] || "<h2>#{component[:title]}</h2>" },
        component[:content]
      ]
    end.flatten
  end

  def raw_content(user_type: nil)
    charts_and_html = []

    header_content(charts_and_html)

    charts_and_html += debug_content

    charts.each do |chart|
      begin
        chart_content(chart, charts_and_html)
      rescue StandardError => e
        logger.info self.class.name
        logger.info e.message
        logger.info e.backtrace
      end
    end

    # charts_and_html += underlying_meters_structured_content(user_type: user_type) if structured_meter_breakdown?(user_type)

    # remove_diagnostics_from_html(charts_and_html, user_type)

    # tack explanation of breakdown onto initial content
    charts_and_html += [{ type: :html, content: individual_meter_level_description_html }] if structured_meter_breakdown?(user_type)

    charts_and_html
  end

  # flatten structured content, so can be presented as single non-accordion html page
  def underlying_meters_content_deprecated(user_type: nil)
    underlying_meters_structured_content(user_type: user_type).map do |meter_content|
      html_title = meter_content[:html_title] || "<h2>#{meter_content[:title]}</h2>"
      [
        { type: :html, content: html_title },
        meter_content[:content]
      ]
    end.flatten
  end
  
  def underlying_meters_structured_content(user_type: nil)
    sorted_underlying_meters.map do |meter_data|
      meter_breakdown_content(meter_data)
    end
  end

  private_class_method def self.definition
    DashboardConfiguration::ADULT_DASHBOARD_GROUP_CONFIGURATIONS.select { |_key, defn| defn[:content_class] == self }.values[0]
  end

  def header_content(charts_and_html)
    charts_and_html.push( { type: :analytics_html, content: '<hr>' } )
    charts_and_html.push( { type: :title, content: self.class.config[:name] } )
    enhanced_title = enhanced_title(self.class.config[:name])
    charts_and_html.push( { type: :enhanced_title, content: enhanced_title})
    charts_and_html.push( { type: :analytics_html, content: format_enhanced_title_for_analytics(enhanced_title)})
  end

  def chart_content(chart, charts_and_html)
    charts_and_html.push( { type: :html,  content: clean_html(chart[:advice_header]) } ) if chart.key?(:advice_header)
    charts_and_html.push( { type: :chart_name, content: chart[:config_name] } )
    charts_and_html.push( { type: :chart, content: chart } )
    charts_and_html.push( { type: :analytics_html, content: AdviceBase.highlighted_dummy_chart_name_html(chart[:config_name]) } )
    charts_and_html.push( { type: :html,  content: clean_html(chart[:advice_footer]) } ) if chart.key?(:advice_footer)
  end

  def enhanced_title(title)
    {
      title:    title,
      rating:   @rating,
      summary:  @summary
    }
  end

  def format_enhanced_title_for_analytics(enhanced_title)
    text = %(
      <h3>Summary rating information (provided by analytics)</h3>
      <%= HtmlTableFormatting.new(['Variable', 'Value'], enhanced_title.to_a).html.gsub('£', '&pound;') %>
    )
    ERB.new(text).result(binding)
  end

  def clean_html(html)
    html.gsub(/[ \t\f\v]{2,}/, ' ').gsub(/^ $/, '').gsub(/\n+|\r+/, "\n").squeeze("\n").strip
  end

  def self.config_base
    DashboardConfiguration::DASHBOARD_PAGE_GROUPS[:adult_analysis_page]
  end

  def self.parse_date(date)
    date.is_a?(String) ? Date.parse(date) : date
  end

  def self.chart_timescale_and_dates(chart_results)
    start_date      = parse_date(chart_results[:x_axis].first)
    end_date        = parse_date(chart_results[:x_axis].last)
    time_scale_days = end_date - start_date + 1
    {
      timescale_days:         time_scale_days,
      timescale_years:        time_scale_days / 365.0,
      timescale_description:  FormatEnergyUnit.format(:years, time_scale_days / 365.0, :html),
      start_date:             chart_results[:x_axis].first,
      end_date:               chart_results[:x_axis].last
    }
  end

  def run_chart(chart_name)
    begin
      chart_manager = ChartManager.new(@school)
      chart = chart_manager.run_standard_chart(chart_name, nil, true)
      @failed_charts.push( { school_name: @school.name, chart_name: chart_name, message: 'Unknown', backtrace: nil } ) if chart.nil?
      chart
    rescue EnergySparksNotEnoughDataException => e
      @failed_charts.push( { school_name: @school.name, chart_name: chart_name,  message: e.message, backtrace: e.backtrace, type: e.class.name, tolerate_failure: tolerate_chart_failure(chart_name) } )
      nil
    rescue => e
      @failed_charts.push( { school_name: @school.name, chart_name: chart_name,  message: e.message, backtrace: e.backtrace, type: e.class.name } )
      nil
    end
  end

  def self.meter_specific_chart_config(chart_name, mpxn)
    name = "#{chart_name}_#{mpxn}".to_sym
    [
      { type: :chart_name,     content: chart_name, mpan_mprn: mpxn },
      { type: :analytics_html, content: AdviceBase.highlighted_dummy_chart_name_html(name) }
    ]
  end

  def promote_analytics_html_to_frontend(charts_and_html)
    charts_and_html.map do |sub_content|
      sub_content[:type] = :html if sub_content[:type] == :analytics_html
      sub_content
    end
  end

  def format_£(value)
    FormatEnergyUnit.format(:£, value, :html)
  end

  def format_kw(value)
    FormatEnergyUnit.format(:kw, value, :html)
  end

  def promote_data
    self.class.config[:promoted_variables].each do |alert_class, variables|
      alert = alert_class.new(@school)
      next unless alert.valid_alert?
      alert.analyse(alert_asof_date, true)
      variables.each do |to, from|
        create_and_set_attr_reader(to, alert.send(from))
      end
    end
  end

  def format_meter_data(meter_data)
    {
      name:     meter_data[:meter].analytics_name,
      kwh:      FormatEnergyUnit.format(:kwh,     meter_data[:annual_kwh], :html),
      £:        FormatEnergyUnit.format(:£,       meter_data[:annual_£],   :html),
      percent:  FormatEnergyUnit.format(:percent, meter_data[:percent],    :html),
      period:   FormatEnergyUnit.format(:years,   meter_data[:years],      :html)
    }
  end

  def sort_underlying_meter_data_by_annual_kwh
    end_date        = aggregate_meter.amr_data.end_date
    start_date      = [end_date - 365, aggregate_meter.amr_data.start_date].max

    total_kwh = aggregate_meter.amr_data.kwh_date_range(start_date, end_date)

    meter_data = available_meters_for_breakdown.map do |meter|
      if meter.amr_data.start_date > end_date || meter.amr_data.end_date < start_date
        nil # deprecated meter outside last year
      else
        sd = [meter.amr_data.start_date, start_date].max
        ed = [meter.amr_data.end_date,   end_date  ].min
        kwh = meter.amr_data.kwh_date_range(sd, ed)
        {
          meter:      meter,
          annual_kwh: kwh,
          annual_£:   meter.amr_data.kwh_date_range(sd, ed, :£),
          percent:    kwh / total_kwh,
          years:      (ed - sd) / 365.0
        }
      end
    end.compact.sort { |md1, md2| md2[:annual_kwh] <=> md1[:annual_kwh] }
  end

  def available_meters_for_breakdown
    @school.underlying_meters(self.class.config[:meter_breakdown][:fuel_type])
  end

  def meter_breakdown_content(meter_data)
    fmd = format_meter_data(meter_data)

    charts_and_html = self.class.config[:meter_breakdown][:charts].map do |chart_name|
      AdviceBase.meter_specific_chart_config(chart_name, meter_data[:meter].mpxn)
    end
    
    {
      title:      "#{fmd[:name]}: #{fmd[:kwh]} #{fmd[:£]} #{fmd[:percent]}",
      html_title: "<h2 style=\"text-align:left;\">#{fmd[:name]}<span style=\"float:right;\">#{fmd[:kwh]} #{fmd[:£]} #{fmd[:percent]}</span></h2>",
      content:    charts_and_html.flatten
    }
  end

  def meter_breakdown_permission?(user_type)
    self.class.config.key?(:meter_breakdown) &&
    self.class.user_permission?(user_type, self.class.config[:meter_breakdown][:user_type][:user_role])
  end

  def structured_meter_breakdown?(user_type)
    meter_breakdown_permission?(user_type) &&
    available_meters_for_breakdown.length > 1
  end

  def sorted_underlying_meters
    @sorted_underlying_meters ||= sort_underlying_meter_data_by_annual_kwh
  end

  def alert_asof_date
    @asof_date ||= aggregate_meter.amr_data.end_date
  end

  def template_data_html
    rows = html_template_variables.to_a
    HtmlTableFormatting.new(['Variable','Value'], rows).html
  end

  def individual_meter_level_description_html
    %q(
      <p>
        To help further understand this analysis, the analysis is now
        broken down to individual meter level:
      </p>
    )
  end

  def create_and_set_attr_reader(key, value)
    status = variable_name_status(key)
    case status
    when :function
      logger.info "promoted variable #{key} already set as function  for #{self.class.name} - overwriting"
      create_var(key, value)
    when :variable
      logger.info "promoted variable #{key} already defined for #{self.class.name} - overwriting"
      instance_variable_set("@#{key}", value)
    else
      create_var(key, value)
    end
  end

  def create_var(key, value)
    self.class.send(:attr_reader, key)
    instance_variable_set("@#{key}", value)
  end

  def variable_name_status(key)
    if respond_to?(key) && !instance_variable_defined?("@#{key.to_s}")
      :function
    else
      instance_variable_defined?("@#{key.to_s}") ? :variable : nil
    end
  end
end
