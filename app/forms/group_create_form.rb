class GroupCreateForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  # フォームオブジェクトのインスタンスにuser属性を持たせる（コントローラからcurrent_userを渡している）
  attr_accessor :user
  # 作成されたグループを外部から参照できるようにする
  attr_reader :group

  # groupsモデル
  attribute :name, :string
  # group_membershipモデル
  attribute :group_nickname, :string
  attribute :role, :string
  # attr_accessor :user  # current_user をセットするため
  validates :name, presence: true, length: { maximum: 30 }
  validates :group_nickname, presence: true, length: { maximum: 20 }

  # フォーム内容を保存する処理
  def save
    return false unless valid?

    ActiveRecord::Base.transaction do
      @group = user.created_groups.build(
        name: name
      )
      @group.group_memberships.build(
        user_id: user.id,
        group_nickname: group_nickname,
        role: :owner
      )
      @group.save!
    end

    true
  # ブロック内で例外が発生すると
  rescue ActiveRecord::RecordInvalid
    false
  end
end
