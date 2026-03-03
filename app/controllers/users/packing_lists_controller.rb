class Users::PackingListsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_schedule, only: %i[show], if: -> { params[:schedule_id].present? }
  before_action :set_packing_list, only: %i[show]

  # GET /packing_list または /schedules/:schedule_id/packing_list
  def show
    @packing_items = @packing_list.packing_items.order(:position)
    @packing_item = @packing_list.packing_items.build
    @form_path = determine_form_path
  end

  private

  def set_schedule
    @schedule = current_user.schedules.find(params[:schedule_id])
  end

  def set_packing_list
    @packing_list = if params[:schedule_id].present?
      @schedule.packing_list || PackingList.create(listable: @schedule)
    else
      current_user.packing_list || PackingList.create(listable: current_user)
    end
  end

  def determine_form_path
    if @packing_list.listable_type == "User"
      packing_list_items_path
    else
      schedule_packing_list_items_path(@packing_list.listable)
    end
  end
end
