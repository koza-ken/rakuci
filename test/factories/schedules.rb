FactoryBot.define do
  factory :schedule do
    schedluable_type { "MyString" }
    schedulable_id { "" }
    name { "MyString" }
    start_date { "2025-11-06" }
    end_date { "2025-11-06" }
    memo { "MyText" }
  end
end
