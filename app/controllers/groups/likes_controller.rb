class Groups::LikesController < ApplicationController
  before_action :set_group
  before_action :set_card
  before_action :check_group_member
  before_action :check_card_in_group
  before_action :set_group_membership

  def create
    @like = @card.likes.build(group_membership: @group_membership)
    if @like.save
      respond_to do |format|
        format.turbo_stream { flash.now[:notice] = t("notices.likes.created") }
        format.html { redirect_to group_card_path(@group, @card), notice: t("notices.likes.created") }
      end
    else
      respond_to do |format|
        format.turbo_stream { render :create, status: :unprocessable_entity }
        format.html { redirect_to group_card_path(@group, @card), alert: t("errors.likes.create_failed") }
      end
    end
  end

  def destroy
    @like = @card.likes.find_by(group_membership: @group_membership)
    @like&.destroy
    respond_to do |format|
      format.turbo_stream { flash.now[:notice] = t("notices.likes.destroyed") }
      format.html { redirect_to group_card_path(@group, @card), notice: t("notices.likes.destroyed") }
    end
  end

  private

  def set_group
    @group = Group.find(params[:group_id])
  end

  def set_card
    @card = Card.find(params[:card_id])
  end

  def set_group_membership
    @group_membership = current_group_membership_for(@group.id)
  end

  # グループに参加しているか確認するフィルター
  def check_group_member
    authorized = if user_signed_in?
      current_user.member_of?(@group)
    else
      GroupMembership.guest_member?(guest_token_for(@group.id), @group.id)
    end

    unless authorized
      redirect_to (user_signed_in? ? groups_path : root_path), alert: t("errors.groups.not_member")
    end
  end

  # カードがそのグループに属しているか確認
  def check_card_in_group
    unless @card.group_card? && @card.cardable_id == @group.id
      redirect_to group_path(@group), alert: t("errors.cards.unauthorized_view")
    end
  end
end
