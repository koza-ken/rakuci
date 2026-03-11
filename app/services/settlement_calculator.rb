class SettlementCalculator
  def initialize(group)
    @group = group
  end

  # グループメンバーごとの精算詳細を計算
  # 戻り値: { group_membership_id => { paid: 支払額, participation: 負担額, settlement: 精算額 } } のハッシュ
  # paid - participation = settlement
  # 正数 = 受け取る、負数 = 支払う
  def calculate
    result = {}

    @group.group_memberships.each do |membership|
      paid = paid_totals_by_membership[membership.id] || 0
      participation = participation_total(membership)
      settlement = paid - participation

      result[membership.id] = {
        paid: paid,
        participation: participation,
        settlement: settlement
      }
    end

    result
  end

  private

  # メンバーごとの支払総額を取得
  # { membership_id => 支払額合計 } のハッシュを返す
  def paid_totals_by_membership
    @group.expenses.group(:paid_by_membership_id).sum(:amount)
  end

  # メンバーごとの負担総額を取得
  # { membership_id => 負担額合計 } のハッシュを返す
  def total_share_by_membership
    # 支出ごとの参加人数を1クエリで取得 { expense_id => 人数 }
    participant_counts = ExpenseParticipant
      .where(expense_id: @group.expense_ids)
      .group(:expense_id).count

    # 支出と参加者の組み合わせを1クエリで取得 -> membership_id=12, expense_id=1, expense_amount=3000
    participant_records = ExpenseParticipant
      .joins(:expense)
      .where(expenses: { group_id: @group.id })
      .select(:group_membership_id, :expense_id, "expenses.amount AS expense_amount")  # メモリを抑えるために取得するカラムを3つ指定

    # メンバーごとの負担額を集計
    share_amount_by_membership = Hash.new(0.0)
    participant_records.each do |record|
      count = participant_counts[record.expense_id] || 1
      share_amount_by_membership[record.group_membership_id] += (record.expense_amount.to_f / count).floor(1)
    end

    total_participation
  end
end
