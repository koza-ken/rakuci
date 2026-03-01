class Groups::LikesController < ApplicationController
  include GroupMemberAuthorization  # グループメンバーのみアクセス許可

  before_action :set_group
  before_action :set_card
  before_action :check_group_member
  before_action :check_card_in_group
  before_action :set_group_membership

  def create
    @like = @card.likes.build(group_membership: @group_membership)
    if @like.save
      @card.likes.reload
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to group_card_path(@group, @card) }
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
    @card.likes.reload
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to group_card_path(@group, @card) }
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

  # カードがそのグループに属しているか確認
  def check_card_in_group
    unless @card.owned_by?(@group)
      redirect_to group_path(@group), alert: t("errors.cards.unauthorized_view")
      return
    end
    # ビューでcard.groupを使う際のSQL発行を防ぐため、既に取得済みの@groupをキャッシュに設定
    @card.cardable = @group
  end
end
