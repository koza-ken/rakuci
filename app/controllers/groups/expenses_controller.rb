class Groups::ExpensesController < ApplicationController
  include GroupMemberAuthorization  # グループメンバーのみアクセス許可

  before_action :set_group
  before_action :check_group_member
  before_action :set_expense, only: %i[edit update destroy]
  before_action :check_expense_owner, only: %i[edit update destroy]

  def index
    @expenses = @group.expenses.ordered_by_paid_at
    @expense = Expense.new
    @current_membership = current_group_membership_for(@group.id)
    # 精算額計算
    @settlements = SettlementCalculator.new(@group).calculate
  end

  def create
    @expense = @group.expenses.build(expense_params)

    # モデルのセッターメソッドでexpense_participantsも生成されている
    if @expense.save
      redirect_to group_expenses_path(@group), notice: t("notices.expenses.created")
    else
      @expenses = @group.expenses.ordered_by_paid_at
      @settlements = SettlementCalculator.new(@group).calculate
      render :index, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @expense.update(expense_params)
      redirect_to group_expenses_path(@group), notice: t("notices.expenses.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @expense.destroy
    redirect_to group_expenses_path(@group), notice: t("notices.expenses.destroyed")
  end

  private

  def set_group
    @group = Group.find(params[:group_id])
  end

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

  def expense_params
    params.require(:expense).permit(:name, :amount, :memo, :paid_at, :paid_by_membership_id, participant_ids: [])
  end
end
