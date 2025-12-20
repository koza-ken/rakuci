module Users
  class ItemListsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_schedule, only: %i[show], if: -> { params[:schedule_id].present? }
    before_action :set_item_list, only: %i[show]

    # GET /item_list または /schedules/:schedule_id/item_list
    def show
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
  end
end
