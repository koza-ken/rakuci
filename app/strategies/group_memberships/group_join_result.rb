# グループ参加処理の結果を表現するオブジェクト
class GroupMemberships::GroupJoinResult
  # サブクラス内の処理の結果を生成
  def initialize(success, error_message = nil, guest_token: nil, group_id: nil)
    @success = success
    @error_message = error_message
    @guest_token = guest_token
    @group_id = group_id
  end

  def success?
    @success == true
  end

  def failure?
    @success == false
  end

  def has_guest_token?
    @guest_token.present?
  end

  # ゲッターメソッド
  def error_message
    @error_message
  end

  def guest_token
    @guest_token
  end

  def group_id
    @group_id
  end

end
