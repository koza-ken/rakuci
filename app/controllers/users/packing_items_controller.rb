class Users::PackingItemsController < ApplicationController
  include PackingItemActions  # create, update, destroyアクションを提供

  before_action :authenticate_user!
  before_action :set_schedule, only: %i[create update destroy], if: -> { params[:schedule_id].present? }
  before_action :set_packing_list, only: %i[create update destroy]
  before_action :set_packing_item, only: %i[update destroy]  # PackingItemActions

  # アクションはconcernに共通化

  private

  def set_schedule
    @schedule = current_user.schedules.find(params[:schedule_id])
  end

  def set_packing_list
    @packing_list = if params[:schedule_id].present?
      @schedule.packing_list
    else
      current_user.packing_list
    end
  end

  # concernの上書き
  def redirect_path
    packing_list_path
  end
end
