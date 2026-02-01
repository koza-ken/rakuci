class DeleteButtonComponent < ViewComponent::Base
  include IconButtonStyling
  include RoutingPathHelper

  def initialize(resource:, scope:, label: nil, show_label: true, confirm_message: nil)
    @resource = resource
    @scope = scope
    @label = label || I18n.t("components.icon_buttons.delete")
    @show_label = show_label  # ボタンにテキストを表示するか
    @confirm_message = confirm_message || I18n.t("components.icon_buttons.delete_confirm")
  end

  # コンポーネントを表示すべきかどうかを判定（falseなら非表示になる、ビューでの呼び出しも不要）
  def render?
    deletable?
  end

  private

  # リソースが削除可能かを判定
  def deletable?
    return true unless @resource.respond_to?(:deletable_by?)  # メソッドの有無を確認
    @resource.deletable_by?(@scope)  # 各リソースに定義しているメソッドを呼び出す
  end

  def delete_path
    # RoutingPathHelperのメソッドを使用しパスを生成する
    path_method = "#{path_prefix}_path"
    send_path_method(path_method)
  end

  def show_label?
    @show_label
  end

  def label
    @label
  end

  def confirm_message
    @confirm_message
  end
end
