# == Schema Information
#
# Table name: schedule_spots
#
#  id                    :bigint           not null, primary key
#  day_number            :integer          not null
#  end_time              :time
#  global_position       :integer          not null
#  is_custom_entry       :boolean          default(FALSE), not null
#  memo                  :text
#  schedulable_type      :string           not null
#  snapshot_address      :string
#  snapshot_name         :string
#  snapshot_phone_number :string
#  snapshot_website_url  :string
#  start_time            :time
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  schedulable_id        :bigint           not null
#  snapshot_category_id  :integer
#  spot_id               :bigint           not null
#
# Indexes
#
#  index_schedule_spots_on_spot_id       (spot_id)
#  index_ss_on_schedulable_and_day       (schedulable_type,schedulable_id,day_number)
#  index_ss_on_schedulable_and_position  (schedulable_type,schedulable_id,global_position) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (spot_id => spots.id)
#
require "test_helper"

class ScheduleSpotTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
