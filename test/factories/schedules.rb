# == Schema Information
#
# Table name: schedules
#
#  id               :bigint           not null, primary key
#  end_date         :date
#  memo             :text
#  name             :string           not null
#  schedulable_type :string           not null
#  start_date       :date
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  schedulable_id   :bigint           not null
#
# Indexes
#
#  index_schedules_on_polymorphic  (schedulable_type,schedulable_id) UNIQUE
#
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
