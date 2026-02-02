class Groups::ItemListsController < ApplicationController
  before_action :set_group
  before_action :check_group_member
  before_action :set_schedule
  before_action :set_item_list, only: %i[show]

  # GET /groups/:group_id/schedule/item_list
  def show
    @items = @item_list.items.order(:position)
    @item = @item_list.items.build
  end

  private

  def set_group
    @group = Group.find(params[:group_id])
  end

  def check_group_member
    authorized = if user_signed_in?
      current_user.member_of?(@group)
    else
      GroupMembership.guest_member_by_token?(stored_guest_token_for(@group.id), @group)
    end

    unless authorized
      redirect_to (user_signed_in? ? groups_path : root_path), alert: t("errors.groups.not_member")
    end
  end

  def set_schedule
    @schedule = @group.schedule
  end

  def set_item_list
    @item_list = @schedule.item_list
  end
end
