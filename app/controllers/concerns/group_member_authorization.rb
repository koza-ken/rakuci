module GroupMemberAuthorization
  extend ActiveSupport::Concern

  private

  def check_group_member
    unless group_member_authorized?
      redirect_to(user_signed_in? ? groups_path : root_path, alert: t("errors.groups.not_member"))
    end
  end

  def group_member_authorized?
    if user_signed_in?
      current_user.member_of?(@group)
    else
      GroupMembership.guest_member_by_token?(stored_guest_token_for(@group.id), @group)
    end
  end
end
