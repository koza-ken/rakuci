class LikesController < ApplicationController
  before_action :set_card
  before_action :set_group_membership

  def create
    @like = @card.likes.build(group_membership: @group_membership)
    if @like.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @card, notice: t("notices.likes.created") }
      end
    else
      respond_to do |format|
        format.turbo_stream { render :create, status: :unprocessable_entity }
        format.html { redirect_to @card, alert: t("errors.likes.create_failed") }
      end
    end
  end

  def destroy
    @like = @card.likes.find_by(group_membership: @group_membership)
    @like&.destroy
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @card, notice: t("notices.likes.destroyed") }
    end
  end

  private

  def set_card
    @card = Card.find(params[:card_id])
  end

  def set_group_membership
    @group_membership = current_group_membership_for(@card.group_id)
  end
end
