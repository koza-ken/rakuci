# グループ参加戦略を選択するファクトリークラ
# 新しく参加方法が増えた場合、Strategyクラスを作成して、↓のcase文に追加（コントローラは修正不要）
class GroupMemberships::GroupJoinStrategy
  def self.for(membership_source)
    case membership_source
    when "existing"
      GroupMemberships::ExistingMemberJoinStrategy
    when "new"
      GroupMemberships::NewMemberJoinStrategy
    else
      # 不正な値が送られたらエラー
      raise ArgumentError, "不正な membership_source: #{membership_source}"
    end
  end
end
