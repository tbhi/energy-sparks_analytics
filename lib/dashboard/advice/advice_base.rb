require_rel '../charting_and_reports/content_base.rb'
class AdviceBase < ContentBase
  include Logging
  attr_reader :summary
  def initialize(school)
    super(school)
    # @user_type = user_type
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

  # override alerts base class, ignore calculation_worked
  def make_available_to_users?
    make_available = relevance == :relevant && enough_data == :enough && failed_charts_required.empty?
    unless make_available
      message = "Alert #{self.class.name} not being made available to users: reason: #{relevance} #{enough_data} failed charts #{@failed_charts.length}"
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
    remove_diagnostics_from_html(charts_and_html, user_type)
  end

  protected def remove_diagnostics_from_html(charts_and_html, user_type)
    if ContentBase.analytics_user?(user_type)
      charts_and_html = promote_analytics_html_to_frontend(charts_and_html) if ContentBase.analytics_user?(user_type)
    else
      charts_and_html.delete_if{ |content_component| %i[analytics_html].include?(content_component[:type]) }
    end
    charts_and_html
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

  private_class_method def self.definition
    DashboardConfiguration::ADULT_DASHBOARD_GROUP_CONFIGURATIONS.select { |_key, defn| defn[:content_class] == self }.values[0]
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

  private

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
    charts_and_html.push( { type: :analytics_html, content: "<h3>Chart: #{chart[:config_name]}</h3>" } )
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
      <p>
        <h3>Summary rating information (provided by analytics)</h3>
        <%= HtmlTableFormatting.new(['Variable', 'Value'], enhanced_title.to_a).html.gsub('£', '&pound;') %>
      <p>
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

  def alert_asof_date
    @asof_date ||= aggregate_meter.amr_data.end_date
  end

  def template_data_html
    rows = html_template_variables.to_a
    HtmlTableFormatting.new(['Variable','Value'], rows).html
  end

  private def create_and_set_attr_reader(key, value)
    self.class.send(:attr_reader, key)
    instance_variable_set("@#{key}", value)
  end
end
