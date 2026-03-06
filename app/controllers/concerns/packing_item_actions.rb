# Users::PackingItemsControllerとGroups::PackingItemsControllerの
# 共通アクション（create,update,destroy）を提供
module PackingItemActions
  extend ActiveSupport::Concern

  included do
    helper_method :item_delete_path, :form_url, :input_class
  end

  def create
    @packing_item = @packing_list.packing_items.build(packing_item_params)

    if @packing_item.save
      @saved_item = @packing_item
      @packing_item = @packing_list.packing_items.build
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to redirect_path, notice: t("notices.packing_items.created") }
      end
    else
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to redirect_path, alert: t("errors.packing_items.create_failed") }
      end
    end
  end

  def update
    if @packing_item.update(packing_item_params)
      # checked, position だけの更新の場合 (AJAX-only)
      if request.format.json? || (packing_item_params.key?(:checked) && !packing_item_params.key?(:name)) || (packing_item_params.key?(:position) && !packing_item_params.key?(:name))
        head :ok
      else
        respond_to do |format|
          format.turbo_stream
          format.html { redirect_to redirect_path, notice: t("notices.packing_items.updated") }
        end
      end
    else
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to redirect_path, alert: t("errors.packing_items.update_failed") }
      end
    end
  end

  def destroy
    @packing_item.destroy

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to redirect_path, notice: t("notices.packing_items.destroyed") }
    end
  end

  private

  # フィルターの順番を調整するため各コントローラから呼び出し
  def set_packing_item
    @packing_item = @packing_list.packing_items.find(params[:id])
  end

  def packing_item_params
    params.require(:packing_item).permit(:name, :checked, :position)
  end

  # 各コントローラーで実装
  def redirect_path
    raise NotImplementedError, "#{self.class}#redirect_path を実装してください"
  end

  def item_delete_path(_item)
    raise NotImplementedError, "#{self.class}#item_delete_path を実装してください"
  end

  def form_url
    raise NotImplementedError, "#{self.class}#form_url を実装してください"
  end

  def input_class
    raise NotImplementedError, "#{self.class}#input_class を実装してください"
  end
end
