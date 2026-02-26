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
  has_many :schedule_spots, dependent: :destroy
  has_one :item_list, as: :listable, dependent: :destroy
  belongs_to :schedulable, polymorphic: true, touch: true

  # バリデーション
  validates :name, presence: true, length: { maximum:  50 }

  # カスタムバリデーション
  validate :only_one_schedule_per_group
  validate :end_date_after_start_date

  # しおりがつくられたらしおりに紐づくもちものリストが作られる
  after_create :create_item_list

  def user_schedule?
    schedulable_type == "User"
  end

  def group_schedule?
    schedulable_type == "Group"
  end

  # しおりの詳細ページへのパスを返す
  def show_path
    if user_schedule?
      # 個人しおりのルーティングはresources（複数形）なので、scheduleのIDが必要->self
      Rails.application.routes.url_helpers.schedule_path(self)
    else
      # グループしおりのルーティングはresource（単数形）なのでscheduleのIDは不要
      # 代わりにどのグループかを示すGroupオブジェクトを渡す->schedulable
      Rails.application.routes.url_helpers.group_schedule_path(schedulable)
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

  # スケジュールの開始日～終了日を曜日付きで返す
  def formatted_date_range
    return nil if start_date.blank? || end_date.blank?
    start_wday = I18n.t("date.day_names")[start_date.wday]
    end_wday = I18n.t("date.day_names")[end_date.wday]
    "#{start_date.strftime('%Y/%m/%d')}（#{start_wday}）～ #{end_date.strftime('%Y/%m/%d')}（#{end_wday}）"
  end

  private

  def create_item_list
    ItemList.create(listable: self)
  end

  # 終了日が開始日以降かをチェック
  def end_date_after_start_date
    return unless start_date.present? && end_date.present?
    if end_date < start_date
      errors.add(:end_date, :greater_than_or_equal_to, count: :start_date)
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
