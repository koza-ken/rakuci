class Groups::SpotsController < ApplicationController
  before_action :set_spot, only: %i[show edit update destroy]
  before_action :set_group, only: %i[new create]
  before_action :set_group_from_spot, only: %i[show edit update destroy]
  before_action :set_card, only: %i[new create]
  before_action :check_group_member
  before_action :check_card_in_group

  def show
  end

  def new
    @spot = @card.spots.build
    @categories = Category.order(display_order: :asc)
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
      @categories = Category.order(display_order: :asc)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @categories = Category.order(display_order: :asc)
  end

  def update
    if @spot.update(spot_params)
      redirect_to group_spot_path(@spot), notice: t("notices.spots.updated")
    else
      @categories = Category.order(display_order: :asc)
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

  def set_group_from_spot
    @group = @spot.card.group
  end

  def set_card
    @card = Card.find(params[:card_id]) if params[:card_id]
  end

  def set_spot
    if params[:card_id]
      @spot = @card.spots.find(params[:id])
    else
      @spot = Spot.find(params[:id])
    end
  end

  def spot_params
    params.require(:spot).permit(:name, :address, :phone_number, :website_url, :category_id, :google_place_id)
  end

  # グループに参加しているか確認するフィルター
  def check_group_member
    authorized = if user_signed_in?
      current_user.member_of?(@group)
    else
      GroupMembership.guest_member_by_token?(stored_guest_token_for(@group.id), @group)
    end

    unless authorized
      redirect_to (user_signed_in? ? groups_path : root_path), alert: t("errors.groups.not_member")
    end
  end

  # カードがそのグループに属しているか確認
  def check_card_in_group
    @card ||= @spot.card
    unless @card.group_card? && @card.cardable_id == @group.id
      redirect_to group_path(@group), alert: t("errors.cards.unauthorized_view")
    end
  end
end
