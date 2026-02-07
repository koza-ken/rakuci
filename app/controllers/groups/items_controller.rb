class Groups::ItemsController < ApplicationController
  include GroupMemberAuthorization  # グループメンバーのみアクセス許可

  before_action :set_group
  before_action :check_group_member
  before_action :set_schedule
  before_action :set_item_list, only: %i[create update destroy]
  before_action :set_item, only: %i[update destroy]

  # POST /groups/:group_id/schedule/item_list/items
  def create
    @item = @item_list.items.build(item_params)

    if @item.save
      @saved_item = @item # リスト追加用に保存済みアイテムを保持
      @item = @item_list.items.build # フォームリセット用に新しい空のインスタンスを作成（newアクションの代わり）
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to group_schedule_item_list_path(@group) }
      end
    else
      # エラー時は@itemを上書きしない（エラーメッセージを保持）
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to group_schedule_item_list_path(@group), alert: t("errors.items.create_failed") }
      end
    end
  end

  # PATCH/PUT /groups/:group_id/schedule/item_list/items/:id
  def update
    if @item.update(item_params)
      # checked, position だけの更新の場合 (AJAX-only)
      if request.format.json? || (item_params.key?(:checked) && !item_params.key?(:name)) || (item_params.key?(:position) && !item_params.key?(:name))
        head :ok
      else
        # 名前の更新の場合 (Turbo Stream)
        respond_to do |format|
          format.turbo_stream
          format.html { redirect_to group_schedule_item_list_path(@group) }
        end
      end
    else
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to group_schedule_item_list_path(@group), alert: t("errors.items.update_failed") }
      end
    end
  end

  # DELETE /groups/:group_id/schedule/item_list/items/:id
  def destroy
    @item.destroy

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to group_schedule_item_list_path(@group) }
    end
  end

  private

  def set_group
    @group = Group.find(params[:group_id])
  end

  def set_schedule
    @schedule = @group.schedule
  end

  def set_item_list
    @item_list = @schedule.item_list
  end

  def set_item
    @item = @item_list.items.find(params[:id])
  end

  def item_params
    params.require(:item).permit(:name, :checked, :position)
  end
end
