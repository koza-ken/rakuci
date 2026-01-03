FactoryBot.define do
  factory :schedule_spot do
    association :schedule, strategy: :create
    association :spot, strategy: :create
    day_number { 1 }
    start_time { "10:00" }
    end_time { "11:00" }
    memo { "Test memo" }
    is_custom_entry { false }
    snapshot_name { "snapshot_name" }
    snapshot_address { "123 Test Street" }
    snapshot_phone_number { "090-1234-5678" }
    snapshot_website_url { "https://example.com" }

    trait :custom do
      spot_id { nil }
      is_custom_entry { true }
    end
  end
end
