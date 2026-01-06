class Groups::ExpensesController < ApplicationController
  before_action :set_group
  before_action :check_group_member

  # GET /groups/:group_id/expenses
  # グループの支出一覧・精算ページを表示
  def index
    @expenses = @group.expenses.ordered_by_paid_at
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
end
