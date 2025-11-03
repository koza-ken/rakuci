# == Schema Information
#
# Table name: cards
#
#  id         :bigint           not null, primary key
#  memo       :text
#  name       :string(50)       not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  group_id   :bigint
#  user_id    :bigint
#
# Indexes
#
#  index_cards_on_group_id  (group_id)
#  index_cards_on_user_id   (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (group_id => groups.id)
#  fk_rails_...  (user_id => users.id)
#
class Card < ApplicationRecord
  has_many :spots, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :liked_group_memberships, through: :likes, source: :group_membership
  belongs_to :user, optional: true
  belongs_to :group, optional: true
  validates :name, presence: true, length: { maximum: 50 }

  # カスタムバリデーション: user_idとgroup_idの排他制約
  validate :must_belong_to_user_or_group

  # 渡されたパラメータから適切なCardインスタンス（個人用カードかグループ用カードか）をつくるメソッド
  def self.build_for(user:, attributes:)
    attributes = attributes.to_h
    # 属性にgroup_idがあれば、グループカードとしてCard.newを返す
    if attributes["group_id"].present? || attributes[:group_id].present?
      new(attributes)
    # group_idがなければ、個人用カードとしてuser.cards.buildを返す
    else
      raise ArgumentError, "個人用カードを作成するにはログインが必要です" unless user
      user.cards.build(attributes)
    end
  end

  # そのユーザーがカードにアクセス可能か
  def accessible_by_user?(user)
    if group_id.present?
      # グループカード：グループメンバーのみ
      user.member_of?(group)
    else
      # 個人カード：所有者のみ
      user_id == user.id
    end
  end

  # ゲストユーザーがカードにアクセス可能か
  def accessible_by_guest?(guest_group_ids)
    return false if group_id.blank?  # 個人カードは不可
    guest_group_ids.include?(group_id)
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
    group_id.present?
  end

  private

  def must_belong_to_user_or_group
    # どちらも無い場合
    if user_id.blank? && group_id.blank?
      errors.add(:base, "ユーザーまたはグループのどちらかに紐づけてください")
    end
    # 両方ある場合
    if user_id.present? && group_id.present?
      errors.add(:base, "ユーザーとグループの両方に紐づけることはできません")
    end
  end
end
