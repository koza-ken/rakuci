class Groups::SpotsController < ApplicationController
  include GroupMemberAuthorization  # グループメンバーのみアクセス許可

  before_action :set_spot, only: %i[show edit update destroy]
  before_action :set_group, only: %i[new create]
  before_action :set_group_from_spot, only: %i[show edit update destroy]
  before_action :check_group_member
  before_action :set_card, only: %i[new create]
  before_action :check_card_in_group

  def show
  end

  def new
    @spot = @card.spots.build
    set_categories
  end

  def create
    @spot = @card.spots.build(spot_params)

    if @spot.save
      respond_to do |format|
        format.turbo_stream { flash.now[:notice] = t("notices.spots.created") }
        format.html { redirect_to group_card_path(@group, @card), notice: t("notices.spots.created") }
      end
    else
      set_categories
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    set_categories
  end

  def update
    if @spot.update(spot_params)
      redirect_to group_spot_path(@spot), notice: t("notices.spots.updated")
    else
      set_categories
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

  # URLをshallow化したのでparamsにgroup_idがない
  def set_group_from_spot
    @card = @spot.card
    @group = @card.group
  end

  def set_card
    @card = Card.find(params[:card_id])
  end

  def set_spot
    @spot = Spot.find(params[:id])
  end

  def set_categories
    @categories = Category.ordered.to_a
  end

  def spot_params
    params.require(:spot).permit(:name, :address, :phone_number, :website_url, :category_id, :google_place_id)
  end

  # カードがそのグループに属しているか確認
  def check_card_in_group
    unless @card.owned_by?(@group)
      redirect_to group_path(@group), alert: t("errors.cards.unauthorized_view")
    end
  end
end
