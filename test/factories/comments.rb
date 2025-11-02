FactoryBot.define do
  factory :comment do
    card { nil }
    group_membership { nil }
    content { "MyText" }
  end
end
