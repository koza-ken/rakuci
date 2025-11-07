class SchedulesController < ApplicationController
  before_action :set_group
  before_action :check_group_member

  def show
    # groupには一つしかscheduleがないので1件目を取得
    @schedule = @group.schedules.first
  end

  private

  def set_group
    @group = Group.find(params[:group_id])
  end

  # グループに参加しているか確認するフィルター（showアクションのフィルター）
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
