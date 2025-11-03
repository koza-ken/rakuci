class SpotsController < ApplicationController
  before_action :set_card, only: [ :new, :create, :edit, :update, :destroy ]
  before_action :set_spot, only: [ :show, :edit, :update, :destroy ]
  before_action :check_show_spot, only: [ :show, :new, :create, :edit, :update, :destroy ]
  before_action :check_create_spots, only: [ :create ]

  def show
  end

  def new
    @spot = @card.spots.build
    @categories = Category.all.order(:display_order)
  end

  def create
    @spot = @card.spots.build(spot_params)
    if @spot.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to card_path(@card), notice: t("notices.spots.created") }
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
      # TODO 更新成功のフラッシュメッセージが正しく表示されない
      redirect_to card_spot_path(@card, @spot), notice: t("notices.spots.updated")
    else
      @categories = Category.all.order(:display_order)
      render :edit, status: :unprocessable_entity, alert: "更新に失敗しました"
    end
  end

  def destroy
    @spot.destroy!
    redirect_to card_path(@card), notice: t("notices.spots.destroyed")
  end

  private

  def spot_params
    params.require(:spot).permit(:name, :address, :phone_number, :website_url, :category_id, :google_place_id)
  end

  def set_card
    @card = Card.find(params[:card_id])
  end

  def set_spot
    @spot = Spot.find(params[:id])
  end

  # ゲストがグループ内でスポットを作成できるようにするフィルター
  def check_create_spots
    # ログインしていない場合（ログインしていたら個人カードのスポット作成）
    unless user_signed_in?
      # ログインしていなくて、個人カードへのスポット作成は、URL直接入力なので拒否
      if @card.group_id.blank?
        render_guest_creation_error(t("errors.spots.guest_creation_not_allowed"))
        return
      end

      # ゲストトークンをcookieから取得（concernのモジュール）
      stored_token = guest_token_for(@card.group_id)

      # ログインしていなくて、tokenがないか、tokenが一致しない場合は権限なし
      unless GroupMembership.guest_member?(stored_token, @card.group_id)
        render_guest_creation_error(t("errors.spots.guest_not_member"))
      end
    end
  end

  # ゲストがスポットの作成に失敗したときのレンダリング処理
  def render_guest_creation_error(message)
    @spot = @card.spots.build
    @categories = Category.all.order(:display_order)
    @spot.errors.add(:base, message)
    render :new, status: :unprocessable_entity
  end

  # スポットにアクセスできるのは、自分の個人用カードか、参加しているグループのカード
  def check_show_spot
    # new、createアクションは@card、show、edit、update、destroyアクションは@spotからcardを取得
    @card ||= @spot&.card

    authorized = @card.accessible?(user: current_user_if_signed_in, guest_group_ids: guest_group_ids)

    unless authorized
      redirect_to (user_signed_in? ? cards_path : root_path),
                  alert: t("errors.spots.unauthorized_view")
    end
  end
end
