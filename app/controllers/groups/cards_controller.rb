class Groups::CardsController < ApplicationController
  before_action :set_group
  before_action :check_group_member
  before_action :set_card, only: %i[show update destroy]

  def show
    @categories = Category.all.includes(:spots).order(:display_order)
    @comments = @card.comments.includes(:group_membership).order(:created_at)
  end

  def new
    @card = Card.new
  end

  def create
    @card = @group.cards.build(card_params)

    if @card.save
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
    @card = @group.cards.find(params[:id])
  end

  def card_params
    params.require(:card).permit(:name, :memo)
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
end
