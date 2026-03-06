class Users::PackingListsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_schedule, only: %i[show], if: -> { params[:schedule_id].present? }
  before_action :set_packing_list, only: %i[show]

  helper_method :item_path, :form_url, :back_path, :input_class

  # GET /packing_list または /schedules/:schedule_id/packing_list
  def show
    @packing_items = @packing_list.packing_items.order(:position)
    @packing_item = @packing_list.packing_items.build
  end

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

  # ヘルパーメソッド
  def item_path(item)
    @schedule.present? ? schedule_packing_list_item_path(@schedule, item) : packing_list_item_path(item)
  end

  def form_url
    @schedule.present? ? schedule_packing_list_items_path(@schedule) : packing_list_items_path
  end

  def back_path
    @schedule.present? ? schedule_path(@schedule) : nil
  end

  def input_class
    ""
  end
end
