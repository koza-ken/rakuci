class CommentsController < ApplicationController
  def create
    @card = Card.find(params[:card_id])
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

  def comment_params
    params.require(:comment).permit(:content)
  end
end
