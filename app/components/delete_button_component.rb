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

  private

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
