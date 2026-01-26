class DeleteButtonComponent < ViewComponent::Base
  include IconButtonStyling

  def initialize(resource:, scope:, label: nil, show_label: true, confirm_message: nil)
    @resource = resource
    @scope = scope  # :group or :user
    @label = label || I18n.t('components.icon_buttons.delete')
    @show_label = show_label  # ボタンにテキストを表示するか
    @confirm_message = confirm_message || I18n.t('components.icon_buttons.delete_confirm')
  end

  private

  def delete_path
    path_method = "#{@scope.class.name.underscore}_#{@resource.class.name.underscore}_path"

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

  def confirm_message
    @confirm_message
  end
end
