# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  display_name           :string(20)
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  provider               :string(64)
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  uid                    :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_provider_and_uid      (provider,uid) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#
class User < ApplicationRecord
  include Hashid::Rails

  # Include default devise modules. \
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [ :google_oauth2 ]
  # ユーザーが「作成した」グループと読めるように関連名にcreatedをつけておく
  has_many :created_groups, class_name: "Group", foreign_key: "created_by_user_id", inverse_of: :creator
  has_many :group_memberships, dependent: :destroy
  has_many :groups, through: :group_memberships
  # ポリモーフィック
  has_many :cards, as: :cardable, dependent: :destroy
  has_many :schedules, as: :schedulable, dependent: :destroy
  has_one :item_list, as: :listable, dependent: :destroy

  validates :display_name, length: { maximum: 20 }, allow_blank: true
  validates :provider, presence: true, if: -> { uid.present? }, length: { maximum: 64 }
  validates :uid, presence: true, if: -> { provider.present? }

  # ユーザーがつくられたらユーザー用のもちものリストが作られる（ユーザー用のリスト）
  after_create :create_item_list

  # ユーザーが特定のグループのメンバーかどうかを確認
  def member_of?(group)
    group_memberships.exists?(group: group)
  end

  # OAuth認証（Google認証など）で登録されたユーザーかどうか
  def oauth_user?
    provider.present? && uid.present?
  end

  # カードとカテゴリごとのスポット件数をグループ化
  def cards_with_spots_grouped
    cards.map { |card| [card, card.spots.group_by(&:category_id)] }
  end

  private

  def create_item_list
    ItemList.create(listable: self)
  end
end
