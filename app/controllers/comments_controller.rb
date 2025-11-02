class CommentsController < ApplicationController
  def create
    @card = Card.find(params[:card_id])
    @comment = @card.comments.build(comment_params)
    @comment.group_membership = current_group_membership
    if @comment.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to card_path(@card), notice: t("notices.comments.created") }
      end
    else
      respond_to do |format|
        format.turbo_stream { render :create, status: :unprocessable_entity }
        format.html { redirect_to card_path(@card), alert: "コメントの投稿に失敗しました" }
      end
    end
  end

  def destroy
  end

  private

  def comment_params
    params.require(:comment).permit(:content)
  end

  def current_group_membership
    if user_signed_in?
      GroupMembership.find_by(user: current_user, group_id: @card.group_id)
    else
      stored_token = guest_token_for(@card.group_id)
      GroupMembership.find_by(guest_token: stored_token, group_id: @card.group_id)
    end
  end
end
