# frozen_string_literal: true

FactoryBot.define do
  factory :temperatures, class: 'Temperatures' do
    transient do
      type { 'temperatures' }
    end

    initialize_with { new(type) }

    trait :with_days do
      transient do
        start_date { Date.yesterday - 7 }
        end_date { Date.yesterday }
        kwh_data_x48 { Array.new(48) { rand(0.0..1.0).round(2) } }
      end

      after(:build) do |temperatures, evaluator|
        (evaluator.start_date..evaluator.end_date).each do |date|
          temperatures.add(date, evaluator.kwh_data_x48)
        end
      end
    end
  end
end
