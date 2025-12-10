class Groups::SpotsController < ApplicationController
  before_action :set_group
  before_action :set_card
  before_action :check_group_member
  before_action :check_card_in_group
  before_action :set_spot, only: %i[show edit update destroy]

  def show
  end

  def new
    @spot = @card.spots.build
    @categories = Category.all.order(:display_order)
  end

  def create
    @spot = @card.spots.build(spot_params)
    # 空文字列のgoogle_place_idをnilに変換（データベースのユニーク制約対策）
    @spot.google_place_id = nil if @spot.google_place_id.blank?

    if @spot.save
      respond_to do |format|
        format.turbo_stream { flash.now[:notice] = t("notices.spots.created") }
        format.html { redirect_to group_card_path(@group, @card), notice: t("notices.spots.created") }
      end
    else
      @categories = Category.all.order(:display_order)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @categories = Category.all.order(:display_order)
  end

  def update
    if @spot.update(spot_params)
      redirect_to group_card_spot_path(@group, @card, @spot), notice: t("notices.spots.updated")
    else
      @categories = Category.all.order(:display_order)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @spot.destroy!
    redirect_to group_card_path(@group, @card), notice: t("notices.spots.destroyed")
  end

  private

  def set_group
    @group = Group.find(params[:group_id])
  end

  def set_card
    @card = Card.find(params[:card_id])
  end

  def set_spot
    @spot = @card.spots.find(params[:id])
  end

  def spot_params
    params.require(:spot).permit(:name, :address, :phone_number, :website_url, :category_id, :google_place_id)
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
