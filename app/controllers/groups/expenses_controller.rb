class Groups::ExpensesController < ApplicationController
  before_action :set_group
  before_action :check_group_member
  before_action :set_expense, only: %i[edit update destroy]
  before_action :check_expense_owner, only: %i[edit update destroy]

  # GET /groups/:group_id/expenses
  # グループの支出一覧・精算ページを表示
  def index
    @expenses = @group.expenses.ordered_by_paid_at
    @expense = Expense.new
    @current_membership = current_group_membership_for(@group.id)
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

  # GET /groups/:group_id/expenses/:id/edit
  # 支出を編集
  def edit
  end

  # PATCH/PUT /groups/:group_id/expenses/:id
  # 支出を更新
  def update
    participant_ids = params[:expense][:participant_ids]&.reject(&:blank?) || []

    if @expense.update(expense_params)
      # 参加者を更新
      @expense.expense_participants.destroy_all
      participant_ids.each do |participant_id|
        @expense.expense_participants.create(group_membership_id: participant_id)
      end
      redirect_to group_expenses_path(@group), notice: t("notices.expenses.updated")
    else
      render :edit
    end
  end

  # DELETE /groups/:group_id/expenses/:id
  # 支出を削除
  def destroy
    @expense.destroy
    redirect_to group_expenses_path(@group), notice: t("notices.expenses.destroyed")
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

  # 支出を取得
  def set_expense
    @expense = @group.expenses.find(params[:id])
  end

  # 支出の作成者のみが編集・削除できるか確認
  def check_expense_owner
    current_membership = current_group_membership_for(@group.id)
    unless current_membership && current_membership.id == @expense.paid_by_membership_id
      redirect_to group_expenses_path(@group), alert: t("errors.expenses.unauthorized")
    end
  end

  # Expense のパラメータをホワイトリスト化
  def expense_params
    params.require(:expense).permit(:name, :amount, :memo, :paid_at, :paid_by_membership_id)
  end
end
