class Users::CardsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_card, only: %i[show update destroy]
  before_action :check_card_owner, only: %i[show update destroy]

  def index
    @categories = Category.order(:display_order).to_a
    @cards_with_spots_by_category = current_user.cards_with_spots_grouped
  end

  def show
    @categories = Category.order(:display_order).to_a
  end

  def new
    @card = Card.new
  end

  def create
    @card = current_user.cards.build(card_params)

    if @card.save
      @categories = Category.order(:display_order).to_a
      respond_to do |format|
        format.turbo_stream { flash.now[:notice] = t("notices.cards.created") }
        format.html { redirect_to cards_path, notice: t("notices.cards.created") }
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @card.update(card_params)
      respond_to do |format|
        format.turbo_stream { flash.now[:notice] = t("notices.cards.updated") }
        format.html { redirect_to card_path(@card), notice: t("notices.cards.updated") }
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
    redirect_to cards_path, notice: t("notices.cards.destroyed")
  end

  private

  def set_card
    @card = Card.find(params[:id])
  end

  def card_params
    params.require(:card).permit(:name, :memo)
  end

  def check_card_owner
    unless @card.owned_by?(current_user)
      redirect_to cards_path, alert: t("errors.cards.unauthorized_view")
    end
  end
end
