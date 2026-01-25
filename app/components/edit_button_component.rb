class EditButtonComponent < ViewComponent::Base
  include IconButtonStyling

  def initialize(resource:, scope:, label: nil)
    @resource = resource
    @scope = scope  # :group or :user
    @label = label || I18n.t('cards.form.edit')
  end

  private

  def edit_path
    # scope と resource から動的にパスメソッド名を組み立てる
    # 例: scope=:group, resource=Spot → "edit_group_spot_path"
    path_method = "edit_#{@scope}_#{@resource.class.name.underscore}_path"
    send(path_method, @resource)
  end

  def label
    @label
  end
end
