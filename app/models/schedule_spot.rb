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
#  spot_id               :bigint
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
class ScheduleSpot < ApplicationRecord
  # アソシエーション
  belongs_to :spot, optional: true  # カスタム入力時はspot_id = NULL
  belongs_to :schedulable, polymorphic: true

  # バリデーション
  validates :global_position, presence: true,
            numericality: { only_integer: true, greater_than: 0 }, # 整数か、0より大きいか
            uniqueness: { scope: [ :schedulable_type, :schedulable_id ] }
  validates :day_number, presence: true,
            numericality: { only_integer: true, greater_than: 0 }
  validates :snapshot_name, length: { maximum: 50 }
  validates :snapshot_address, length: { maximum: 255 }
  validates :snapshot_phone_number, length: { maximum: 20 }
  validates :snapshot_website_url, length: { maximum: 500 }

  # カスタムバリデーション
  validate :spot_or_custom_entry_valid
  validate :end_time_after_start_time

  # スコープ
  scope :ordered, -> { order(:global_position) }
  scope :on_day, ->(day) { where(day_number: day) }
  scope :for_user, ->(user) { where(schedulable_type: "User", schedulable_id: user.id) }
  scope :for_group, ->(group) { where(schedulable_type: "Group", schedulable_id: group.id) }

  # 個人用スケジュールかどうか
  def personal_schdule?
    schedulable_type == "User"
  end

  # グループ用スケジュールかどうか
  def group_schedule?
    schedulable_type == "Group"
  end

  # 表示名を取得（スナップショット > Spot > デフォルト）
  def display_name
    snapshot_name.presence || spot&.name || "予定"
  end

  private

  # spot_id と is_custom_entry の整合性をチェック
  def spot_or_custom_entry_valid
    if is_custom_entry
      # カスタム入力の場合：spot_idはNULL、snapshot_nameは必須
      if spot_id.present?
        errors.add(:spot_id, "はカスタム入力時には指定できません")
      end
      if snapshot_name.blank?
        errors.add(:snapshot_name, "を入力してください")
      end
    else
      # Spot参照の場合：spot_idは必須
      if spot_id.blank?
        errors.add(:spot_id, "を指定してください")
      end
    end
  end

  # 終了時刻が開始時刻より後かチェック
  def end_time_after_start_time
    return if start_time.blank? || end_time.blank?

    if end_time <= start_time
      errors.add(:end_time, "は開始時刻より後の時刻を指定してください")
    end
  end
end
