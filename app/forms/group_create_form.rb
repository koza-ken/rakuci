# Group（グループ名）+ GroupMembership（グループ内での呼び名）を検証・保存
class GroupCreateForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  # Group 属性
  attribute :name, :string

  # GroupMembership 属性
  attribute :group_nickname, :string

  # saveメソッドのvalid?でバリデーションを実行
  validates :name, presence: true, length: { maximum: 30 }
  validates :group_nickname, presence: true, length: { maximum: 20 }

  def initialize(user: nil, **attributes) # **はハッシュをキ－ワード引数として受け取る
    @user = user  # user は ActiveModel 属性ではなく、直接セット
    super(**attributes)  # name と group_nickname を設定
  end

  # 初期化時に設定されたuser（コントローラーから渡されるcurrent_user）
  def user
    @user
  end

  # save後に作成されたgroup
  def group
    @group
  end

  def save
    return false unless valid?

    ActiveRecord::Base.transaction do
      @group = user.created_groups.build(name: name)
      @group.group_memberships.build(
        user_id: user.id,
        group_nickname: group_nickname,
        role: :owner
      )
      @group.save!
    end

    true
  rescue ActiveRecord::RecordInvalid
    false
  end
end
