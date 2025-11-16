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
#  snapshot_address      :string
#  snapshot_name         :string
#  snapshot_phone_number :string
#  snapshot_website_url  :string
#  start_time            :time
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  google_place_id       :string
#  schedule_id           :bigint           not null
#  snapshot_category_id  :integer
#  spot_id               :bigint
#
# Indexes
#
#  index_schedule_spots_on_spot_id    (spot_id)
#  index_ss_on_schedule_and_day       (schedule_id,day_number)
#  index_ss_on_schedule_and_position  (schedule_id,global_position) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (schedule_id => schedules.id)
#  fk_rails_...  (spot_id => spots.id)
#
require "test_helper"

class ScheduleSpotTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
