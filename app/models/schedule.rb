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
class Schedule < ApplicationRecord
  include Hashid::Rails

  # アソシエーション
  belongs_to :schedulable, polymorphic: true
  has_many :schedule_spots, dependent: :destroy

  # バリデーション
  validates :name, presence: true, length: { maximum: 50 }
  validates :schedulable_type, presence: true
  validates :end_date, comparison: { greater_than: :start_date }, allow_blank: true

  # カスタムバリデーション
  validate :only_one_schedule_per_group

  # しおりのタイプを返す（個人 or グループ）
  def schedule_type
    schedulable_type == "User" ? :personal : :group
  end

  # グループしおりの場合、グループオブジェクトを返す
  def group
    Group.find_by(id: schedulable_id) if schedulable_type == "Group"
  end

  # しおりの詳細ページへのパスを返す
  def show_path
    if schedule_type == :personal
      Rails.application.routes.url_helpers.schedule_path(self)
    else
      Rails.application.routes.url_helpers.group_schedule_path(group, self)
    end
  end

  # しおりの日数を返す
  def days
    return 1 if start_date.blank? || end_date.blank?
    (end_date - start_date).to_i + 1
  end

  # 指定された日目に対応する日付を返す（フォーマット付き）
  def formatted_date_for_day(day_number)
    return nil if start_date.blank?
    date = start_date + (day_number - 1).days
    # i18n から日付フォーマットと曜日を取得
    date_format = I18n.t("date.formats.schedule_day")
    wday = I18n.t("date.day_names")[date.wday]
    date.strftime(date_format) + "（#{wday}）"
  end

  private

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
