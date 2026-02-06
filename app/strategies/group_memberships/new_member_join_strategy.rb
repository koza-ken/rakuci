# グループ新規メンバー参加ストラテジー
# 「はじめて参加する」から新しいニックネームを入力して参加する場合
class GroupMemberships::NewMemberJoinStrategy < GroupMemberships::GroupJoinStrategyBase
  def execute
    # はじめて参加するので、メンバーシップを作成する
    membership = @group.group_memberships.build(group_nickname: @membership_params[:group_nickname], role: "member")

    # ログイン済みユーザー or ゲストのどちらかを設定
    guest_token = membership.attach_user_or_guest_token(@current_user)
    unless guest_token != false
      return GroupMemberships::GroupJoinResult.new(false, I18n.t("errors.groups.membership_failed"))
    end

    # ゲストトークンをセットする必要があれば result に含める
    GroupMemberships::GroupJoinResult.new(true, guest_token: guest_token, group_id: @group.id)
  end
end
