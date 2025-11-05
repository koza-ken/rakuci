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
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  # groupモデルでcreatorにしたのでuserモデルもあわせておく
  has_many :created_groups, class_name: "Group", foreign_key: "created_by_user_id", inverse_of: :creator
  has_many :cards, dependent: :destroy
  has_many :group_memberships, dependent: :destroy
  has_many :groups, through: :group_memberships
  has_many :schedule_spots, as: :schedulable

  validates :display_name, length: { maximum: 20 }, allow_blank: true
  validates :provider, presence: true, if: -> { uid.present? }, length: { maximum: 64 }, allow_blank: true
  validates :uid, presence: true, if: -> { provider.present? }

  # ユーザーが特定のグループのメンバーかどうかを確認
  def member_of?(group)
    group_memberships.exists?(group: group)
  end
end
