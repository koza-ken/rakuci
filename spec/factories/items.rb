FactoryBot.define do
  factory :item do
    item_list_id { 1 }
    name { "MyString" }
    checked { false }
    position { 1 }
  end
end
