FactoryBot.define do
  factory :schedule_spot do
    association :schedule, strategy: :create
    association :spot, strategy: :create
    day_number { 1 }
    start_time { "10:00" }
    end_time { "11:00" }
    memo { "Test memo" }
    name { "name" }
    address { "123 Test Street" }
    phone_number { "090-1234-5678" }
    website_url { "https://example.com" }

    trait :custom do
      spot_id { nil }
    end
  end
end
