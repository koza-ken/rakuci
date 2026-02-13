# グループ既存メンバー参加ストラテジー
# 「過去に参加したことある」から既存のニックネームを選択して参加する場合
class GroupMemberships::ExistingMemberJoinStrategy < GroupMemberships::GroupJoinStrategyBase
  def execute
    # 選択したニックネームからメンバーシップを探す
    membership = @group.group_memberships.find_by(group_nickname: @membership_params[:group_nickname])
    unless membership
      return GroupMemberships::GroupJoinResult.new(false, I18n.t("errors.groups.user_not_found"))
    end

    # 見つかったメンバーシップに、user_id かトークンを紐づける
    guest_token = membership.attach_user_or_guest_token(@current_user)
    if guest_token == false
      return GroupMemberships::GroupJoinResult.new(false, I18n.t("errors.groups.membership_failed"))
    end

    # 成功（ゲストトークンをセットする必要があれば result に含める）
    GroupMemberships::GroupJoinResult.new(true, guest_token: guest_token, group_id: @group.id)
  end
end
