class Users::ItemsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_schedule, only: %i[create update destroy], if: -> { params[:schedule_id].present? }
  before_action :set_item_list, only: %i[create update destroy]
  before_action :set_item, only: %i[update destroy]

  # POST /item_list/items または /schedules/:schedule_id/item_list/items
  def create
    @item = @item_list.items.build(item_params)
    @form_path = determine_form_path # 常にパスを設定

    if @item.save
      @saved_item = @item # リスト追加用に保存済みアイテムを保持
      @item = @item_list.items.build # フォームリセット用に新しい空のインスタンスを作成（newアクションの代わり）
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
    # checked, position フィールドのみの更新か、name フィールドの更新かで分岐
    if @item.update(item_params)
      # checked, position だけの更新の場合 (AJAX-only)
      if request.format.json? || (item_params.key?(:checked) && !item_params.key?(:name)) || (item_params.key?(:position) && !item_params.key?(:name))
        head :ok
      else
        # 名前の更新の場合 (Turbo Stream)
        respond_to do |format|
          format.turbo_stream
          format.html { redirect_to item_list_path, notice: t("notices.items.updated") }
        end
      end
    else
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to item_list_path, alert: t("errors.items.update_failed") }
      end
    end
  end

  # DELETE /item_list/items/:id または /schedules/:schedule_id/item_list/items/:id
  def destroy
    @item.destroy

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to item_list_path, notice: t("notices.items.destroyed") }
    end
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

  def determine_form_path
    if @item_list.listable_type == "User"
      item_list_items_path
    else
      schedule_item_list_items_path(@item_list.listable)
    end
  end

  def item_params
    params.require(:item).permit(:name, :checked, :position)
  end
end
