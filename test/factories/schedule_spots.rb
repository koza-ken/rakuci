FactoryBot.define do
  factory :schedule_spot do
    schedulable_type { "MyString" }
    schedulable_id { "" }
    spot { nil }
    global_position { 1 }
    day_number { 1 }
    start_time { "2025-11-05 21:13:03" }
    end_time { "2025-11-05 21:13:03" }
    is_custom_entry { false }
    snapshot_name { "MyString" }
    snapshot_category_id { 1 }
    snapshot_address { "MyString" }
    snapshot_phone_number { "MyString" }
    snapshot_website_url { "MyString" }
    memo { "MyText" }
  end
end
