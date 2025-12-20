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

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [ :google_oauth2 ]
  # groupモデルでcreatorにしたのでuserモデルもあわせておく
  has_many :created_groups, class_name: "Group", foreign_key: "created_by_user_id", inverse_of: :creator
  has_many :cards, as: :cardable, dependent: :destroy
  has_many :group_memberships, dependent: :destroy
  has_many :groups, through: :group_memberships
  has_many :schedules, as: :schedulable, dependent: :destroy
  has_one :item_list, as: :listable, dependent: :destroy

  validates :display_name, length: { maximum: 20 }, allow_blank: true
  validates :provider, presence: true, if: -> { uid.present? }, length: { maximum: 64 }
  validates :uid, presence: true, if: -> { provider.present? }

  # ユーザーがつくられたらユーザー用のもちものリストが作られる
  after_create :create_item_list

  # ユーザーが特定のグループのメンバーかどうかを確認
  def member_of?(group)
    group_memberships.exists?(group: group)
  end

  # OAuth認証（Google認証など）で登録されたユーザーかどうか
  def oauth_user?
    provider.present? && uid.present?
  end

  def self.from_omniauth(auth)
    # 既存のOAuth認証ユーザーを探す
    user = find_by(provider: auth.provider, uid: auth.uid)
    return user if user

    # 既存のOAuth認証ユーザーがなければ、同じメールアドレスの既存ユーザーを探す
    user = find_by(email: auth.info.email)

    # 同じメールアドレスの既存ユーザーが見つかったら
    if user
      # 既存ユーザーにOAuth情報を紐付け（provider/uidが未設定の場合のみ）
      if user.provider.blank? && user.uid.blank?
        user.update!(
          provider: auth.provider,
          uid: auth.uid
        )
      end
      return user
    end

    # ユーザーがなければ、新規ユーザーを作成
    create!(
      provider: auth.provider,
      uid: auth.uid,
      email: auth.info.email,
      password: Devise.friendly_token[0, 20],
      display_name: sanitized_display_name(auth)
    )
  end

  def self.sanitized_display_name(auth)
    display_name = auth.info.name.presence || auth.info.first_name.presence || auth.info.email.split("@").first
    display_name.to_s[0, 20]
  end
  private_class_method :sanitized_display_name

  private

  def create_item_list
    ItemList.create(listable: self)
  end
end
