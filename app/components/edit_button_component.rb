class EditButtonComponent < ViewComponent::Base
  include IconButtonStyling
  include RoutingPathHelper

  def initialize(resource:, scope:, label: nil, show_label: true)
    @resource = resource
    @scope = scope
    @label = label || I18n.t("components.icon_buttons.edit")
    @show_label = show_label  # ボタンにテキストを表示するか
  end

  private

  def edit_path
    # RoutingPathHelperのメソッドを使用しパスを生成する
    path_method = "edit_#{path_prefix}_path"
    send_path_method(path_method)
  end

  def show_label?
    @show_label
  end

  def label
    @label
  end
end
