class EditButtonComponent < ViewComponent::Base
  include IconButtonStyling

  def initialize(resource:, scope:, label: nil, show_label: true)
    @resource = resource
    @scope = scope
    @label = label || I18n.t('components.icon_buttons.edit')
    @show_label = show_label  # ボタンにテキストを表示するか
  end

  private

  def edit_path
    path_method = "edit_#{@scope.class.name.underscore}_#{@resource.class.name.underscore}_path"

    case
    # グループしおり（singular resource）：groupのみ渡す
    when @scope.class.name == "Group" && @resource.class.name == "Schedule"
      send(path_method, @scope)
    # グループ配下の複数形リソース（card, expense, spot等）：groupとresourceを渡す
    when @scope.class.name == "Group"
      send(path_method, @scope, @resource)
    else
      # ユーザーのリソース：resourceのみ渡す
      send(path_method, @resource)
    end
  end

  def show_label?
    @show_label
  end

  def label
    @label
  end
end
