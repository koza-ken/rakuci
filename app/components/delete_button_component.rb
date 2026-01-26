class DeleteButtonComponent < ViewComponent::Base
  include IconButtonStyling

  def initialize(resource:, scope:, label: nil, confirm_message: nil, show_label: true)
    @resource = resource
    @scope = scope  # :group or :user
    @label = label || I18n.t('components.icon_buttons.delete')
    @confirm_message = confirm_message || I18n.t('cards.form.confirm_delete')
    @show_label = show_label
  end

  private

  def delete_path
    path_method = "#{@scope.class.name.underscore}_#{@resource.class.name.underscore}_path"

    # グループしおりのパスは、groups/:id/scheduleなので、groupを渡す
    if @scope.class.name == "Group" && @resource.class.name == "Schedule"
      send(path_method, @scope)
    else
      # それ以外は通常どおりリソースを渡す
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
