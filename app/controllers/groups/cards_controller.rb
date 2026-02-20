class Groups::CardsController < ApplicationController
  include GroupMemberAuthorization  # グループメンバーのみアクセス許可

  before_action :set_group
  before_action :check_group_member
  before_action :set_card, only: %i[show update destroy]
  before_action :check_card_in_group, only: %i[show update destroy]

  def show
    @categories = Category.order(:display_order).to_a
    @comments = @card.comments.includes(:group_membership).order(:created_at)
  end

  def new
    @card = Card.new
  end

  def create
    @card = @group.cards.build(card_params)

    if @card.save
      @categories = Category.order(:display_order).to_a
      respond_to do |format|
        format.turbo_stream { flash.now[:notice] = t("notices.cards.created") }
        format.html { redirect_to group_path(@group), notice: t("notices.cards.created") }
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @card.update(card_params)
      respond_to do |format|
        format.turbo_stream { flash.now[:notice] = t("notices.cards.updated") }
        format.html { redirect_to group_card_path(@group, @card), notice: t("notices.cards.updated") }
      end
    else
      respond_to do |format|
        format.turbo_stream { render :update, status: :unprocessable_entity }
        format.html { render :show, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @card.destroy!
    redirect_to group_path(@group), notice: t("notices.cards.destroyed")
  end

  private

  def set_group
    @group = Group.find(params[:group_id])
  end

  def set_card
    @card = Card.find(params[:id])
  end

  def card_params
    params.require(:card).permit(:name, :memo)
  end

  # カードがそのグループに属しているか確認
  def check_card_in_group
    unless @card.owned_by?(@group)
      redirect_to group_path(@group), alert: t("errors.cards.unauthorized_view")
    end
  end
end
