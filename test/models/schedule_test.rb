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
#  index_schedules_on_polymorphic  (schedulable_type,schedulable_id) UNIQUE WHERE ((schedulable_type)::text = 'Group'::text)
#
require "test_helper"

class ScheduleTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
