require_relative '../../lib/dashboard/time_of_year.rb'
require 'awesome_print'
require 'date'
# temporary class to enhance meter data model prior to this data being
# stored in the database, and ensure PH's YAML meter representation
# which already holds this data stays in sync with postgres
class MeterAttributes
  extend Logging

  def self.attributes(meter, type)
    mpan_mprn = meter.mpan_mprn.to_i # treat as integer even if loaded as string
    return nil unless METER_ATTRIBUTE_DEFINITIONS.key?(mpan_mprn)
    return nil unless METER_ATTRIBUTE_DEFINITIONS[mpan_mprn].key?(type)

    butes = METER_ATTRIBUTE_DEFINITIONS[mpan_mprn][type]

    # fill in weekends for all Bath derived data
    if type == :meter_corrections && meter.building.area_name == 'Bath'
      butes.push( {auto_insert_missing_readings: { type: :weekends}})
    end
    butes
  end

  METER_ATTRIBUTE_DEFINITIONS = {
    # ==============================St Marks===================================
    8841599005 => { # gas Heating 1
      meter_corrections: [
        no_heating_in_summer_set_missing_to_zero: {
          start_toy: TimeOfYear.new(4, 1),
          end_toy:   TimeOfYear.new(9, 30)
        }
      ],
      function: [ :heating_only ]
    },
    13684909 => { # gas Heating 2
      meter_corrections: [
        {
          no_heating_in_summer_set_missing_to_zero: {
            start_toy: TimeOfYear.new(4, 1),
            end_toy:   TimeOfYear.new(9, 30)
          }
        },
        {
          rescale_amr_data: {
            start_date: Date.new(2009, 1, 1),
            end_date: Date.new(2012, 2, 12),
            scale:  (1.0 / 31.1) # incorrectly scaled imperial/metric data
          }
        }
      ],
      function: [:heating_only]
    },
    13685103 => { # gas Orchard Lodge
      meter_corrections: [
        no_heating_in_summer_set_missing_to_zero: {
          start_toy: TimeOfYear.new(4, 1),
          end_toy:   TimeOfYear.new(9, 30)
        }
      ],
      function: [ :heating_only ]
    },
    13685204 => { # gas kitchen
      meter_corrections: [ :set_all_missing_to_zero ],
      function: [ :kitchen_only ]
    },
    13685002 => { # gas hot water
      meter_corrections: [ :set_all_missing_to_zero ],
      function: [ :hotwater_only ]
    },
    # ==============================Castle Primary=============================
    2200015105145 => {
      aggregation:  [
        :deprecated_include_but_ignore_end_date,
        :deprecated_include_but_ignore_start_date
      ] 
    },
    2200015105163 => {
      aggregation:  [
        :deprecated_include_but_ignore_end_date,
        :deprecated_include_but_ignore_start_date
      ] 
    },
    2200041803451 => { aggregation:  [:deprecated_include_but_ignore_end_date] },
    2200042676990 => { aggregation:  [:ignore_start_date] }, # succeeds meters above
    # ==============================St Saviours Juniors========================
    4234023603 => { # current gas meter
      aggregation:  [ :ignore_start_date ]
    },
    46341710 => { # old gas meter
      aggregation:  [ :deprecated_include_but_ignore_end_date ],
      meter_corrections: [
        {
          rescale_amr_data: {
            start_date: Date.new(2009, 9, 8),
            end_date: Date.new(2015, 8, 17),
            scale:  (11.0 / 31.1) # incorrectly scaled imperial/metric data
          }
        },
        {
          set_bad_data_to_zero: {
            start_date: Date.new(2015, 7, 31),
            end_date:   Date.new(2015, 8, 17)
          }
        }
      ]
    },
    2200012408737 => { # current electricity meter
      aggregation:  [ :ignore_start_date ]
    },
    2200012408773 => { # deprecated electricity meter
      aggregation:  [
        :deprecated_include_but_ignore_end_date,
        :deprecated_include_but_ignore_start_date
      ]
    },
    2200012408791 => { # deprecated electricity meter
      aggregation:  [ :deprecated_include_but_ignore_end_date ] 
    },
    2200012408782 => { # deprecated electricity meter
      aggregation:  [ :deprecated_include_but_ignore_end_date ] 
    },
    2200012408816 => { # deprecated electricity meter
      aggregation:  [
        :deprecated_include_but_ignore_end_date,
        :deprecated_include_but_ignore_start_date
      ]
    },
    # ==============================Marksbury==================================
    2200011879013 => {
      meter_corrections: [
        {
          set_bad_data_to_zero: {
            start_date: Date.new(2011, 10, 6),
            end_date:   Date.new(2015, 10, 17)
          }
        }
      ]
    },
    # ==============================Paulton Junior=============================
    13678903 => {
      meter_corrections: [
        {
          set_bad_data_to_zero: {
            start_date: Date.new(2016, 4, 27),
            end_date:   Date.new(2016, 4, 27)
          },
        },
        {
          readings_start_date: Date.new(2014, 9, 30)
        }
      ]
    },
    # ==============================Roundhill==================================
    75665806 => {
      meter_corrections: [
        {
          rescale_amr_data: {
            start_date: Date.new(2009, 1, 1),
            end_date: Date.new(2009, 1, 1),
            scale:  (1.0 / 31.1) # incorrectly scaled imperial/metric data
          }
        }
      ]
    },
    # ==============================St Johns===============================
    9206222810 => {
      meter_corrections: [ { readings_start_date: Date.new(2017, 2, 21) } ]
    }
  }.freeze
  private_constant :METER_ATTRIBUTE_DEFINITIONS
end
