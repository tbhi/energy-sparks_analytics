# frozen_string_literal: true

require 'spec_helper'
require 'dashboard'
class CustomAlert < ContentBase
  # Test access to instance variables
  attr_reader :a_number, :a_cost, :a_priority

  TEMPLATE_VARIABLES = {
    a_number: {
      description: 'A number',
      units: Integer
    },
    some_string: {
      description: 'A string',
      units: String
    },
    a_cost: {
      description: 'A GBP value',
      units: :£
    },
    a_range: {
      description: 'A GBP range',
      units: :£_range
    },
    stripped: {
      description: 'stripped',
      units: TrueClass
    },
    date: {
      description: 'mapped to native type',
      units: Date
    },
    a_table: {
      description: 'a table',
      units: :table,
      header: %w[x y],
      column_types: [String, :£]
    },
    a_chart: {
      description: 'a chart',
      units: :chart
    },
    a_priority: {
      description: 'priority',
      units: Integer,
      priority_code: 'XYZ'
    }
  }.freeze

  def initialize(number: 100, cost: 50)
    @a_number = number
    @a_cost = cost
    @a_priority = number * 2
  end

  # Test calling methods dynamically
  def some_string
    'Returned via method'
  end

  # ContentBase doesn't implement this, so sub-classes must
  def self.template_variables
    { 'Custom Alert' => TEMPLATE_VARIABLES }
  end
end

describe ContentBase do
  describe '#i18n_prefix' do
    it 'returns correct prefix' do
      expect(CustomAlert.new.i18n_prefix).to eq 'analytics.custom_alert'
    end
  end

  context 'when listing variables' do
    describe '#front_end_template_variables' do
      before do
        @variables = CustomAlert.front_end_template_variables
      end

      it 'produces basic variables' do
        expect(@variables).to match({
                                      'Custom Alert' => a_hash_including(
                                        a_cost: {
                                          description: 'A GBP value',
                                          units: :£
                                        }
                                      )
                                    })
      end

      it 'converts some units' do
        expect(@variables).to match({
                                      'Custom Alert' => a_hash_including(
                                        a_number: {
                                          description: 'A number',
                                          units: :integer
                                        },
                                        a_priority: {
                                          description: 'priority',
                                          priority_code: 'XYZ',
                                          units: :integer
                                        },
                                        some_string: {
                                          description: 'A string',
                                          units: :string
                                        },
                                        date: {
                                          description: 'mapped to native type',
                                          units: :date
                                        }
                                      )
                                    })
      end

      it 'adds variables for ranges' do
        expect(@variables).to match({
                                      'Custom Alert' => a_hash_including(
                                        a_range_low: {
                                          description: 'A GBP range low',
                                          units: :£
                                        },
                                        a_range_high: {
                                          description: 'A GBP range high',
                                          units: :£
                                        }
                                      )
                                    })
      end

      it 'strips other variables' do
        expect(@variables['Custom Alert']).not_to have_key(:a_chart)
        expect(@variables['Custom Alert']).not_to have_key(:a_table)
        expect(@variables['Custom Alert']).not_to have_key(:stripped)
      end
    end

    describe '#priority_template_variables' do
      before do
        @variables = CustomAlert.priority_template_variables
      end

      it 'returns only the priority variables' do
        expect(@variables).to eq({
                                   a_priority: {
                                     description: 'priority',
                                     units: :integer,
                                     priority_code: 'XYZ'
                                   }
                                 })
      end
    end

    describe '#front_end_template_charts' do
      before do
        @charts = CustomAlert.front_end_template_charts
      end

      it 'returns only charts' do
        expect(@charts).to eq(
          a_chart: {
            description: 'a chart',
            units: :chart
          }
        )
      end
    end

    describe '#front_end_template_tables' do
      before do
        @tables = CustomAlert.front_end_template_tables
      end

      it 'returns only tables' do
        expect(@tables).to eq(
          a_table: {
            description: 'a table',
            units: :table,
            header: %w[x y],
            column_types: [String, :£]
          }
        )
      end
    end
  end

  context 'when returning data' do
    describe '#front_end_template_data' do
      before do
        @template_data = CustomAlert.new.front_end_template_data
      end

      it 'returns the expected values' do
        expect(@template_data).to eq({
                                       a_cost: '£50',
                                       a_number: '100',
                                       a_priority: '200',
                                       some_string: 'Returned via method'
                                     })
      end
    end

    describe '#priority_template_data' do
      before do
        @template_data = CustomAlert.new.priority_template_data
      end

      it 'returns the expected values' do
        expect(@template_data).to eq({
                                       a_priority: 200
                                     })
      end
    end
  end
end
