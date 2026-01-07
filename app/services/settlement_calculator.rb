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
      paid = paid_total(membership)
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

  # メンバーが支払った総額
  def paid_total(membership)
    @group.expenses.where(paid_by_membership_id: membership.id).sum(:amount)
  end

  # メンバーが参加した支出額の合計を、参加人数で割った一人分
  # 小数第1位で切り捨て
  def participation_total(membership)
    total_participation = 0.0

    @group.expenses.joins(:expense_participants)
          .where(expense_participants: { group_membership_id: membership.id })
          .each do |expense|
      # 支出額を参加人数で割る（小数第1位で切り捨て）
      participant_count = expense.expense_participants.count
      total_participation += (expense.amount.to_f / participant_count).floor(1)
    end

    total_participation
  end
end
