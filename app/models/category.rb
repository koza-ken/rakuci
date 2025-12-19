# == Schema Information
#
# Table name: categories
#
#  id            :bigint           not null, primary key
#  display_order :integer          not null
#  name          :string(20)       not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_categories_on_display_order  (display_order) UNIQUE
#
class Category < ApplicationRecord
  # そのカテゴリのスポットがある場合、カテゴリの削除時にエラー
  has_many :spots, dependent: :restrict_with_error
  validates :name, presence: true, length: { maximum: 20 }
  validates :display_order, presence: true, uniqueness: true

  # カテゴリ名に対応するアイコンのパーシャル名を返す
  def icon_partial
    case name
    when "観光地"
      "shared/icon/card_icon_sightseeing"
    when "グルメ"
      "shared/icon/card_icon_gourmet"
    when "体験"
      "shared/icon/card_icon_activity"
    when "買い物"
      "shared/icon/card_icon_shopping"
    else
      nil
    end
  end

  # カテゴリ名に対応する背景色のTailwindクラスを返す
  def background_color_class
    case name
    when "観光地"
      "bg-sky-100/60"
    when "グルメ"
      "bg-red-100/60"
    when "体験"
      "bg-green-100/60"
    when "買い物"
      "bg-violet-100/70"
    else
      "bg-white" # デフォルト
    end
  end

  # カテゴリ名に対応する文字色のTailwindクラスを返す
  def text_color_class
    case name
    when "観光地"
      "text-sky-600"
    when "グルメ"
      "text-red-500"
    when "体験"
      "text-green-500"
    when "買い物"
      "text-violet-700"
    else
      "text-text" # デフォルト
    end
  end
end
