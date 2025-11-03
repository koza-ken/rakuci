class CommentsController < ApplicationController
  before_action :set_card
  before_action :set_comment, only: [ :destroy ]
  before_action :check_comment_owner, only: [ :destroy ]

  def create
    @comment = @card.comments.build(comment_params)
    @comment.group_membership = current_group_membership_for(@card.group_id)
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
    @comment.destroy
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to card_path(@card), notice: "コメントを削除しました" }
    end
  end

  private

  def set_card
    @card = Card.find(params[:card_id])
  end

  def set_comment
    @comment = @card.comments.find(params[:id])
  end

  def check_comment_owner
    current_membership = current_group_membership_for(@card.group_id)
    unless current_membership && current_membership.id == @comment.group_membership_id
      respond_to do |format|
        format.turbo_stream {
          redirect_to card_path(@card), alert: "削除する権限がありません"
        }
        format.html { redirect_to card_path(@card), alert: "削除する権限がありません" }
      end
    end
  end

  def comment_params
    params.require(:comment).permit(:content)
  end
end
