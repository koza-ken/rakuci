class Groups::PackingListsController < ApplicationController
  include GroupMemberAuthorization  # グループメンバーのみアクセス許可

  before_action :set_group
  before_action :check_group_member
  before_action :set_schedule
  before_action :set_packing_list, only: %i[show]

  helper_method :item_delete_path, :form_url, :back_path, :input_class

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

  # ヘルパーメソッド
  def item_delete_path(item)
    group_schedule_packing_list_item_path(@group, item)
  end

  def form_url
    group_schedule_packing_list_items_path(@group)
  end

  def back_path
    group_schedule_path(@group)
  end

  def input_class
    "flex-1"
  end

end
