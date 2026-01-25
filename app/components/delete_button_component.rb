class DeleteButtonComponent < ViewComponent::Base
  include IconButtonStyling

  def initialize(resource:, scope:, label: nil, confirm_message: nil, show_label: true)
    @resource = resource
    @scope = scope  # :group or :user
    @label = label || I18n.t('cards.form.delete')
    @confirm_message = confirm_message || I18n.t('cards.form.confirm_delete')
    @show_label = show_label
  end

  private

  def delete_path
    # scope と resource から動的にパスメソッド名を組み立てる
    # 例: scope=:group, resource=Spot → "group_spot_path"
    path_method = "#{@scope}_#{@resource.class.name.underscore}_path"
    send(path_method, @resource)
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