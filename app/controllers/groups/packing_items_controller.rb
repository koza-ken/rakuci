class Groups::PackingItemsController < ApplicationController
  include GroupMemberAuthorization  # グループメンバーのみアクセス許可
  include PackingItemActions        # create, update, destroyアクションを提供

  before_action :set_group
  before_action :check_group_member
  before_action :set_schedule
  before_action :set_packing_list, only: %i[create update destroy]
  before_action :set_packing_item, only: %i[update destroy]  # PackingItemActions

  # アクションはconcernに共通化

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

  # concernの上書き
  def redirect_path
    group_schedule_packing_list_path(@group)
  end
end
