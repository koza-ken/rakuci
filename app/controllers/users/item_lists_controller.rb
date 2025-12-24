class Users::ItemListsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_schedule, only: %i[show], if: -> { params[:schedule_id].present? }
  before_action :set_item_list, only: %i[show]

  # GET /item_list または /schedules/:schedule_id/item_list
  def show
    @items = @item_list.items.order(:position)
    @item = @item_list.items.build
    @form_path = determine_form_path
  end

  private

  def set_schedule
    @schedule = current_user.schedules.find(params[:schedule_id])
  end

  def set_item_list
    @item_list = if params[:schedule_id].present?
      @schedule.item_list
    else
      current_user.item_list
    end
  end

  def determine_form_path
    if @item_list.listable_type == 'User'
      item_list_items_path
    else
      schedule_item_list_items_path(@item_list.listable)
    end
  end
end
