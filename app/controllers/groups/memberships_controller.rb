class Groups::MembershipsController < ApplicationController
  before_action :set_group
  before_action :set_membership, only: %i[ destroy ]
  before_action :check_owner_permission, only: %i[ destroy ]
  before_action :check_group_member

  def destroy
    @membership = @group.group_memberships.find(params[:id])

    # オーナーは削除できない
    if @membership.owner?
      redirect_to group_path(@group), alert: t("errors.memberships.cannot_delete_owner")
      return
    end

    @membership.destroy
    respond_to do |format|
      format.turbo_stream { flash.now[:notice] = t("notices.memberships.deleted") }
      format.html { redirect_to group_path(@group), notice: t("notices.memberships.deleted") }
    end
  end

  private

  def set_group
    @group = Group.find(params[:group_id])
  end

  def set_membership
    @membership = @group.group_memberships.find(params[:id])
  end

  # グループのオーナーのみがメンバーを削除できる
  def check_owner_permission
    unless current_user&.id == @group.created_by_user_id
      redirect_to group_path(@group), alert: t("errors.memberships.not_authorized")
    end
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
