# == Schema Information
#
# Table name: groups
#
#  id                 :bigint           not null, primary key
#  invite_token       :string(64)       not null
#  name               :string(30)       not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  created_by_user_id :bigint           not null
#
# Indexes
#
#  index_groups_on_created_by_user_id  (created_by_user_id)
#  index_groups_on_invite_token        (invite_token) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (created_by_user_id => users.id)
#
class Group < ApplicationRecord
  include Hashid::Rails

  # コールバック（招待用のトークン設定）
  before_validation :generate_invite_token, on: :create

  belongs_to :creator, class_name: "User", foreign_key: "created_by_user_id", inverse_of: :created_groups
  has_many :cards, as: :cardable, dependent: :destroy
  has_many :group_memberships, dependent: :destroy
  has_many :members, through: :group_memberships, source: :user
  has_one :schedule, as: :schedulable, dependent: :destroy
  has_many :expenses, dependent: :destroy

  validates :created_by_user_id, presence: true
  validates :name, presence: true, length: { maximum: 30 }
  validates :invite_token, presence: true, length: { maximum: 64 }, uniqueness: true

  # グループが指定されたユーザーによって作成されたかを判定
  def created_by?(user)
    created_by_user_id == user&.id
  end

  # グループが指定されたユーザーによって削除可能かを判定
  def deletable_by?(user)
    created_by?(user)
  end

  private

  # 招待用トークンの生成
  def generate_invite_token
    self.invite_token ||= SecureRandom.urlsafe_base64(48)
  end
end
