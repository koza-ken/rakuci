# == Schema Information
#
# Table name: groups
#
#  id                 :bigint           not null, primary key
#  invite_token       :string(64)       not null
#  name               :string(30)       not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  created_by_user_id :integer          not null
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
  # コールバック（招待用のトークン設定）
  before_validation :generate_invite_token, on: :create

  belongs_to :creator, class_name: "User", foreign_key: "created_by_user_id", inverse_of: :created_groups
  has_many :cards, dependent: :destroy
  has_many :group_memberships, dependent: :destroy
  has_many :members, through: :group_memberships, source: :user
  has_many :schedule_spots, as: :schedulable

  validates :created_by_user_id, presence: true
  validates :name, presence: true, length: { maximum: 30 }
  validates :invite_token, presence: true, length: { maximum: 64 }, uniqueness: true
  validates :trip_name, length: { maximum: 50 }, allow_blank: true

  # 終了日が開始日より後になるように
  validate :end_date_after_start_date

  private

  def end_date_after_start_date
    return if start_date.blank? || end_date.blank?

    if end_date < start_date
      errors.add(:end_date, "は開始日より後の日付を設定してください")
    end
  end

  # 招待用トークンの生成
  def generate_invite_token
    self.invite_token ||= SecureRandom.urlsafe_base64(48)
  end
end
