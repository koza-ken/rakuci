class Users::ItemsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_schedule, only: %i[create update destroy], if: -> { params[:schedule_id].present? }
  before_action :set_item_list, only: %i[create update destroy]
  before_action :set_item, only: %i[update destroy]

  # POST /item_list/items または /schedules/:schedule_id/item_list/items
  def create
    @item = @item_list.items.build(item_params)

    if @item.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to item_list_path, notice: t("notices.items.created") }
      end
    else
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to item_list_path, alert: t("errors.items.create_failed") }
      end
    end
  end

  # PATCH/PUT /item_list/items/:id または /schedules/:schedule_id/item_list/items/:id
  def update
  end

  # DELETE /item_list/items/:id または /schedules/:schedule_id/item_list/items/:id
  def destroy
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

  def set_item
    @item = @item_list.items.find(params[:id])
  end

  def item_params
    params.require(:item).permit(:name, :checked, :position)
  end
end
