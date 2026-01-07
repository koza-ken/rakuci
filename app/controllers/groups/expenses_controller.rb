class Groups::ExpensesController < ApplicationController
  before_action :set_group
  before_action :check_group_member

  # GET /groups/:group_id/expenses
  # グループの支出一覧・精算ページを表示
  def index
    @expenses = @group.expenses.ordered_by_paid_at
    @expense = Expense.new
    # 精算額計算
    @settlements = SettlementCalculator.new(@group).calculate
  end

  # POST /groups/:group_id/expenses
  # 支出を追加
  def create
    # 参加者IDを取得
    participant_ids = params[:expense][:participant_ids]&.reject(&:blank?) || []

    @expense = @group.expenses.build(expense_params)
    @expense.paid_at = Date.current if @expense.paid_at.blank?

    # 先に expense_participants を build してから save
    participant_ids.each do |participant_id|
      @expense.expense_participants.build(group_membership_id: participant_id)
    end

    if @expense.save
      redirect_to group_expenses_path(@group), notice: t("notices.expenses.created")
    else
      @expenses = @group.expenses.ordered_by_paid_at
      @settlements = SettlementCalculator.new(@group).calculate
      render :index
    end
  end

  private

  # グループを取得
  def set_group
    @group = Group.find(params[:group_id])
  end

  # グループに参加しているか確認するフィルター
  def check_group_member
    authorized = if user_signed_in?
      current_user.member_of?(@group)
    else
      GroupMembership.guest_member?(guest_token_for(@group.id), @group.id)
    end

    unless authorized
      redirect_to (user_signed_in? ? groups_path : root_path), alert: t("errors.groups.not_member")
    end
  end

  # Expense のパラメータをホワイトリスト化
  def expense_params
    params.require(:expense).permit(:name, :amount, :memo, :paid_at, :paid_by_membership_id)
  end
end
