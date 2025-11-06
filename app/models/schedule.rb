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
class Schedule < ApplicationRecord
  # アソシエーション
  belongs_to :schedulable, polymorphic: true
  has_many :schedule_spots, dependent: :destroy

  # バリデーション
  validates :name, presence: true, length: { maximum: 50 }
  validates :schedulable_type, presence: true
  validates :schedulable_id, presence: true

  # カスタムバリデーション
  validate :end_date_after_start_date
  validate :only_one_schedule_per_group

  private

  # 終了日が開始日より後になるように
  def end_date_after_start_date
    return if start_date.blank? || end_date.blank?

    if end_date < start_date
      errors.add(:end_date, "は開始日より後の日付を設定してください")
    end
  end

  # グループは1つのスケジュールのみ持つことができる
  def only_one_schedule_per_group
    return unless schedulable_type == "Group"

    # グループが既に別のしおりを持っていないか確認
    existing_schedule = Schedule.where(schedulable_type: "Group", schedulable_id: schedulable_id)
                                .where.not(id: id).exists?

    if existing_schedule
      errors.add(:base, "グループが作成できるしおりは1つまでです")
    end
  end
end
