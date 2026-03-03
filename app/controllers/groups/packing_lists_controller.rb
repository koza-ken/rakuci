class Groups::PackingListsController < ApplicationController
  include GroupMemberAuthorization  # グループメンバーのみアクセス許可

  before_action :set_group
  before_action :check_group_member
  before_action :set_schedule
  before_action :set_packing_list, only: %i[show]

  # GET /groups/:group_id/schedule/packing_list
  def show
    @packing_items = @packing_list.packing_items.order(:position)
    @packing_item = @packing_list.packing_items.build
  end

  private

  def set_group
    @group = Group.find(params[:group_id])
  end

  def set_schedule
    @schedule = @group.schedule
  end

  def set_packing_list
    @packing_list = @schedule.packing_list
  end
end
