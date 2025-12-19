class Users::SpotsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_card
  before_action :check_card_owner
  before_action :set_spot, only: %i[show edit update destroy]

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
        format.html { redirect_to card_path(@card), notice: t("notices.spots.created") }
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
      redirect_to card_spot_path(@card, @spot), notice: t("notices.spots.updated")
    else
      @categories = Category.order(display_order: :asc)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @spot.destroy!
    redirect_to card_path(@card), notice: t("notices.spots.destroyed")
  end

  private

  def set_card
    @card = Card.find(params[:card_id])
  end

  def set_spot
    @spot = @card.spots.find(params[:id])
  end

  def spot_params
    params.require(:spot).permit(:name, :address, :phone_number, :website_url, :category_id, :google_place_id)
  end

  def check_card_owner
    unless @card.accessible?(user: current_user, guest_group_ids: [])
      redirect_to cards_path, alert: t("errors.cards.unauthorized_view")
    end
  end
end
