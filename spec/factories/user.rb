FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password" }
    display_name { "TestUser" }

    trait :oauth do
      provider { "google_oauth2" }
      sequence(:uid) { |n| "uid#{n}" }
    end
  end
end
