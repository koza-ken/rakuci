class LikesController < ApplicationController
  before_action :set_card
  before_action :check_group_card_access
  before_action :set_group_membership

  def create
    @like = @card.likes.build(group_membership: @group_membership)
    if @like.save
      respond_to do |format|
        format.turbo_stream { flash.now[:notice] = t("notices.likes.created") }
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
      format.turbo_stream { flash.now[:notice] = t("notices.likes.destroyed") }
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

  def check_group_card_access
    # グループカードかチェック
    unless @card.group_card?
      redirect_to cards_path, alert: t("errors.not_group_card")
      return
    end

    # グループメンバーかチェック
    membership = current_group_membership_for(@card.group_id)
    unless membership
      redirect_to (user_signed_in? ? cards_path : root_path),
                  alert: t("errors.not_group_member")
    end
  end
end
