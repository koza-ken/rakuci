class Users::PackingItemsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_schedule, only: %i[create update destroy], if: -> { params[:schedule_id].present? }
  before_action :set_packing_list, only: %i[create update destroy]
  before_action :set_packing_item, only: %i[update destroy]

  # POST /packing_list/items または /schedules/:schedule_id/packing_list/items
  def create
    @packing_item = @packing_list.packing_items.build(packing_item_params)
    @form_path = determine_form_path # 常にパスを設定

    if @packing_item.save
      @saved_item = @packing_item # リスト追加用に保存済みアイテムを保持
      @packing_item = @packing_list.packing_items.build # フォームリセット用に新しい空のインスタンスを作成（newアクションの代わり）
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to packing_list_path, notice: t("notices.packing_items.created") }
      end
    else
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to packing_list_path, alert: t("errors.packing_items.create_failed") }
      end
    end
  end

  # PATCH/PUT /packing_list/items/:id または /schedules/:schedule_id/packing_list/items/:id
  def update
    # checked, position フィールドのみの更新か、name フィールドの更新かで分岐
    if @packing_item.update(packing_item_params)
      # checked, position だけの更新の場合 (AJAX-only)
      if request.format.json? || (packing_item_params.key?(:checked) && !packing_item_params.key?(:name)) || (packing_item_params.key?(:position) && !packing_item_params.key?(:name))
        head :ok
      else
        # 名前の更新の場合 (Turbo Stream)
        respond_to do |format|
          format.turbo_stream
          format.html { redirect_to packing_list_path, notice: t("notices.packing_items.updated") }
        end
      end
    else
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to packing_list_path, alert: t("errors.packing_items.update_failed") }
      end
    end
  end

  # DELETE /packing_list/items/:id または /schedules/:schedule_id/packing_list/items/:id
  def destroy
    @packing_item.destroy

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to packing_list_path, notice: t("notices.packing_items.destroyed") }
    end
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

  def set_packing_item
    @packing_item = @packing_list.packing_items.find(params[:id])
  end

  def determine_form_path
    if @packing_list.listable_type == "User"
      packing_list_items_path
    else
      schedule_packing_list_items_path(@packing_list.listable)
    end
  end

  def packing_item_params
    params.require(:packing_item).permit(:name, :checked, :position)
  end
end
