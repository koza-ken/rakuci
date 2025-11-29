FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password" }
    display_name { Faker::Name.name[0...20] } # keep under 20 chars

    # oauthのテスト
    # trait :oauth do
    #   provider { "google_oauth2" }
    #   sequence(:uid) { |n| "uid#{n}" }
    # end
  end
end
