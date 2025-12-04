FactoryBot.define do
  factory :spot do
    sequence(:name) { |n| "spot#{n}" }
    address { "123 Test Street" }
    phone_number { "090-1234-5678" }
    website_url { "https://example.com" }

    association :card, strategy: :create
    association :category, strategy: :create
  end
end
