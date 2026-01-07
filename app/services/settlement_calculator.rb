class SettlementCalculator
  def initialize(group)
    @group = group
  end

  # グループメンバーごとの精算額を計算
  # 戻り値: { group_membership_id => settlement_amount } のハッシュ
  # 正数 = 受け取る、負数 = 支払う
  def calculate
    result = {}

    @group.group_memberships.each do |membership|
      paid_amount = paid_total(membership)
      participation_amount = participation_total(membership)

      # 支払った額 - 参加分の支出額 = 精算額
      # 正数なら受け取る（立て替えた分が返ってくる）
      # 負数なら支払う（支出分を払う）
      result[membership.id] = paid_amount - participation_amount
    end

    result
  end

  private

  # メンバーが支払った総額
  def paid_total(membership)
    @group.expenses.where(paid_by_membership_id: membership.id).sum(:amount)
  end

  # メンバーが参加した支出額の合計を、参加人数で割った一人分
  def participation_total(membership)
    total_participation = 0

    @group.expenses.joins(:expense_participants)
          .where(expense_participants: { group_membership_id: membership.id })
          .each do |expense|
      # 支出額を参加人数で割る
      participant_count = expense.expense_participants.count
      total_participation += expense.amount / participant_count
    end

    total_participation
  end
end
