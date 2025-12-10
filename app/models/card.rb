# == Schema Information
#
# Table name: cards
#
#  id            :bigint           not null, primary key
#  cardable_type :string           not null
#  memo          :text
#  name          :string(50)       not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  cardable_id   :bigint           not null
#
# Indexes
#
#  index_cards_on_cardable_type_and_cardable_id  (cardable_type,cardable_id)
#
class Card < ApplicationRecord
  include Hashid::Rails

  has_many :spots, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :liked_group_memberships, through: :likes, source: :group_membership
  belongs_to :cardable, polymorphic: true, touch: true
  validates :name, presence: true, length: { maximum: 50 }

  # カードのタイプを返す（個人用 or グループ用）
  def card_type
    cardable_type == "User" ? :personal : :group
  end

  # そのユーザーがカードにアクセス可能か
  def accessible_by_user?(user)
    if card_type == :group
      # グループカード：グループメンバーのみ
      user.member_of?(cardable)
    else
      # 個人カード：所有者のみ
      cardable_id == user.id
    end
  end

  # ゲストユーザーがカードにアクセス可能か
  def accessible_by_guest?(guest_group_ids)
    return false if card_type == :personal  # 個人カードは不可
    guest_group_ids.include?(cardable_id)
  end

  # 引数にuserがあれば、accessible_by_user?でカードにアクセス可能か確認
  #  userがなければ（ゲスト）、参加済みグループのidにカードのidが含まれるかを確認
  def accessible?(user:, guest_group_ids:)
    if user.present?
      accessible_by_user?(user)
    else
      accessible_by_guest?(guest_group_ids)
    end
  end

  def group_card?
    card_type == :group
  end

  # グループカードの場合、グループオブジェクトを返す
  def group
    cardable if card_type == :group
  end

  # 個人カードの場合、ユーザーオブジェクトを返す
  def user
    cardable if card_type == :personal
  end

  # 指定されたメンバーシップがこのカードにいいねしているか
  def liked_by?(group_membership)
    return false unless group_membership
    likes.exists?(group_membership: group_membership)
  end
end
