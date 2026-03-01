class Groups::CommentsController < ApplicationController
  include GroupMemberAuthorization  # グループメンバーのみアクセス許可

  before_action :set_group
  before_action :set_card
  before_action :check_group_member
  before_action :check_card_in_group
  before_action :set_comment, only: %i[destroy]
  before_action :set_group_membership
  before_action :check_comment_owner, only: %i[destroy]

  def create
    @comment = @card.comments.build(comment_params)
    @comment.group_membership = @group_membership

    if @comment.save
      respond_to do |format|
        format.turbo_stream { flash.now[:notice] = t("notices.comments.created") }
        format.html { redirect_to group_card_path(@group, @card), notice: t("notices.comments.created") }
      end
    else
      respond_to do |format|
        format.turbo_stream { render :create, status: :unprocessable_entity }
        format.html { redirect_to group_card_path(@group, @card), alert: t("errors.comments.create_failed") }
      end
    end
  end

  def destroy
    @comment.destroy
    respond_to do |format|
      format.turbo_stream { flash.now[:notice] = t("notices.comments.destroyed") }
      format.html { redirect_to group_card_path(@group, @card), notice: t("notices.comments.destroyed") }
    end
  end

  private

  def set_group
    @group = Group.find(params[:group_id])
  end

  def set_card
    @card = Card.find(params[:card_id])
  end

  def set_comment
    @comment = @card.comments.find(params[:id])
  end

  def comment_params
    params.require(:comment).permit(:content)
  end

  def set_group_membership
    @group_membership = current_group_membership_for(@group.id)
  end

  def check_comment_owner
    unless @group_membership && @group_membership.id == @comment.group_membership_id
      redirect_to group_card_path(@group, @card), alert: t("errors.comments.unauthorized_delete")
    end
  end

  # カードがそのグループに属しているか確認
  def check_card_in_group
    unless @card.owned_by?(@group)
      redirect_to group_path(@group), alert: t("errors.cards.unauthorized_view")
    end
  end
end
