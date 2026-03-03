class Groups::PackingItemsController < ApplicationController
  include GroupMemberAuthorization  # グループメンバーのみアクセス許可

  before_action :set_group
  before_action :check_group_member
  before_action :set_schedule
  before_action :set_packing_list, only: %i[create update destroy]
  before_action :set_packing_item, only: %i[update destroy]

  # POST /groups/:group_id/schedule/packing_list/items
  def create
    @packing_item = @packing_list.packing_items.build(packing_item_params)

    if @packing_item.save
      @saved_item = @packing_item # リスト追加用に保存済みアイテムを保持
      @packing_item = @packing_list.packing_items.build # フォームリセット用に新しい空のインスタンスを作成（newアクションの代わり）
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to group_schedule_packing_list_path(@group) }
      end
    else
      # エラー時は@packing_itemを上書きしない（エラーメッセージを保持）
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to group_schedule_packing_list_path(@group), alert: t("errors.packing_items.create_failed") }
      end
    end
  end

  # PATCH/PUT /groups/:group_id/schedule/packing_list/items/:id
  def update
    if @packing_item.update(packing_item_params)
      # checked, position だけの更新の場合 (AJAX-only)
      if request.format.json? || (packing_item_params.key?(:checked) && !packing_item_params.key?(:name)) || (packing_item_params.key?(:position) && !packing_item_params.key?(:name))
        head :ok
      else
        # 名前の更新の場合 (Turbo Stream)
        respond_to do |format|
          format.turbo_stream
          format.html { redirect_to group_schedule_packing_list_path(@group) }
        end
      end
    else
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to group_schedule_packing_list_path(@group), alert: t("errors.packing_items.update_failed") }
      end
    end
  end

  # DELETE /groups/:group_id/schedule/packing_list/items/:id
  def destroy
    @packing_item.destroy

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to group_schedule_packing_list_path(@group) }
    end
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

  def set_packing_item
    @packing_item = @packing_list.packing_items.find(params[:id])
  end

  def packing_item_params
    params.require(:packing_item).permit(:name, :checked, :position)
  end
end
