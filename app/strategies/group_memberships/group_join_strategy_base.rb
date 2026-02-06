# グループ参加ストラテジーの基底クラス
class GroupMemberships::GroupJoinStrategyBase
  # サブクラス共通
  def initialize(group, membership_params, current_user)
    @group = group
    @membership_params = membership_params
    @current_user = current_user
  end

  # サブクラスでexecuteメソッドを実装していない場合
  def execute
    raise NotImplementedError, "サブクラスで実装してください"
  end
end
