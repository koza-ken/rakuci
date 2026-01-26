class EditButtonComponent < ViewComponent::Base
  include IconButtonStyling

  def initialize(resource:, scope:, label: nil)
    @resource = resource
    @scope = scope
    @label = label || I18n.t('components.icon_buttons.edit')
  end

  private

  def edit_path
    path_method = "edit_#{@scope.class.name.underscore}_#{@resource.class.name.underscore}_path"

    # グループしおりのパスは、groups/:id/scheduleなので、groupを渡す
    if @scope.class.name == "Group" && @resource.class.name == "Schedule"
      send(path_method, @scope)
    else
      # それ以外は通常どおりresourceを渡す
      send(path_method, @resource)
    end
  end

  def label
    @label
  end
end
