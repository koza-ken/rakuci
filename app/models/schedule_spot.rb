# == Schema Information
#
# Table name: schedule_spots
#
#  id              :bigint           not null, primary key
#  address         :string
#  day_number      :integer          not null
#  end_time        :time
#  global_position :integer          not null
#  memo            :text
#  name            :string
#  phone_number    :string
#  start_time      :time
#  website_url     :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  category_id     :integer
#  google_place_id :string
#  schedule_id     :bigint           not null
#  spot_id         :bigint
#
# Indexes
#
#  index_schedule_spots_on_spot_id  (spot_id)
#  index_ss_on_schedule_and_day     (schedule_id,day_number)
#
# Foreign Keys
#
#  fk_rails_...  (schedule_id => schedules.id)
#  fk_rails_...  (spot_id => spots.id)
#
class ScheduleSpot < ApplicationRecord
  include Hashid::Rails

  # アソシエーション
  belongs_to :schedule
  belongs_to :spot, optional: true  # spotから追加したかどうかを区別する

  # バリデーション
  # global_position は acts_as_list が自動で管理するためバリデーション不要
  validates :day_number, presence: true,
            numericality: { only_integer: true, greater_than: 0 }
  validates :name, presence: true, length: { maximum: 50 }
  validates :address, length: { maximum: 255 }
  validates :phone_number, length: { maximum: 20 }
  validates :website_url, format: { with: URI::DEFAULT_PARSER.make_regexp([ "http", "https" ]) }, length: { maximum: 500 }, allow_blank: true

  # カスタムバリデーション
  validate :end_time_after_start_time

  # 並び替えgem acts_as_list
  acts_as_list column: :global_position, scope: [ :schedule_id, :day_number ]

  # スコープ
  scope :ordered, -> { order(:global_position) }
  scope :on_day, ->(day) { where(day_number: day) }

  # 表示名を取得（登録名 > デフォルト）
  def display_name
    name.presence || "予定"
  end

  # 開始時刻と終了時刻をフォーマット（"HH:MM ～ HH:MM" または "HH:MM ～" または "～ HH:MM" の形式）
  def formatted_time_range
    start = start_time&.strftime("%H:%M")
    finish = end_time&.strftime("%H:%M")

    if start && finish
      "#{start} ～ #{finish}"
    elsif start
      "#{start} ～"
    elsif finish
      "～ #{finish}"
    else
      "---"
    end
  end

  # カテゴリに応じた背景色のTailwindクラスを返す
  def category_background_color
    # category_id はしおり登録時の値、なければ元Spotのカテゴリを参照
    id = category_id || spot&.category_id
    return "bg-white" unless id

    category = Category.find_by(id: id)
    category&.background_color_class || "bg-white"
  end

  def self.create_from_spot(schedule, spot, day_number: 1)
    schedule.schedule_spots.build(
      spot_id: spot.id,
      day_number: day_number,
      global_position: schedule.schedule_spots.count + 1,
      name: spot.name,
      address: spot.address,
      phone_number: spot.phone_number,
      website_url: spot.website_url,
      category_id: spot.category_id,
      google_place_id: spot.google_place_id
    )
  end

  private

  # 終了時刻が開始時刻以降かをチェック
  def end_time_after_start_time
    if start_time.present? && end_time.present? && end_time < start_time
      errors.add(:end_time, :greater_than, count: :start_time)
    end
  end
end
