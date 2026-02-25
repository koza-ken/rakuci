class Users::ScheduleSpotsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_schedule_spot, only: %i[show edit update destroy move_higher move_lower]
  before_action :set_schedule_from_schedule_spot, only: %i[show edit update destroy move_higher move_lower]

  def show
    @category = Category.find_by(id: @schedule_spot.category_id)
  end

  def new
    add_spot_from_card? ? new_from_card : new_from_schedule
  end

  def create
    add_spot_from_card? ? create_from_card : create_from_schedule
  end

  def edit
  end

  # スポットの編集フォームによる更新と、並び替えによる更新を処理
  def update
    if @schedule_spot.update(schedule_spot_params)
      respond_to do |format|
        # 並び替えによる更新のレスポンス
        format.json { head :ok }
        # 編集フォームによる更新のレスポンス
        format.html { redirect_to user_schedule_spot_path(@schedule_spot), notice: t("notices.schedule_spots.updated") }
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @schedule_spot.destroy
      redirect_to schedule_path(@schedule), notice: t("notices.schedule_spots.destroyed"), turbo: false
    end
  end

  # 並び替えacts_as_listのメソッド
  def move_higher
    @schedule_spot.move_higher
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to schedule_path(@schedule) }
    end
  end

  def move_lower
    @schedule_spot.move_lower
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to schedule_path(@schedule) }
    end
  end

  private

  def set_schedule_spot
    @schedule_spot = ScheduleSpot.includes(:spot).find(params[:id])
  end

  def set_schedule_from_schedule_spot
    @schedule = @schedule_spot.schedule
  end

  def schedule_spot_params
    params.require(:schedule_spot).permit(:name, :address, :website_url, :phone_number, :category_id, :google_place_id, :start_time, :end_time, :memo, :day_number, :global_position)
  end

  def set_categories
    @categories = Category.order(display_order: :asc).to_a
  end

  def add_spot_from_card?
    # cardからしおりにスポットを追加する場合paramsにspotが含まれる
    params[:spot_ids].present? || params[:spot_id].present?
  end

  def new_from_card
    @card = current_user.cards.find(params[:card_id])
    @schedules = current_user.schedules
    # カードから複数のスポットを追加するかの判定
    if params[:spot_ids].present?
      @spot_ids = Array(params[:spot_ids])
      @spots = Spot.where(id: @spot_ids)
    else
      @spot = Spot.find(params[:spot_id])
    end
  end

  def new_from_schedule
    @schedule = current_user.schedules.find(params[:schedule_id])
    @schedule_spot = ScheduleSpot.new
    set_categories
  end

  def create_from_card
    @card = current_user.cards.find(params[:card_id])
    @schedule = current_user.schedules.find(params[:schedule_id])
    # カードから追加するスポットを順番に保存していく
    spot_ids = params[:spot_ids].presence || [ params[:spot_id] ].compact
    spots = Spot.where(id: spot_ids)
    results = spots.map { |spot| ScheduleSpot.create_from_spot(@schedule, spot).save }
    # スポットの保存結果を返す
    if results.all?
      redirect_to card_path(@card), notice: t("notices.user_schedule_spots.created_multiple", count: results.size)
    elsif results.none?
      redirect_to card_path(@card), alert: t("errors.user_schedule_spots.create_failed")
    else
      added = results.count(true)
      failed = results.count(false)
      redirect_to card_path(@card), notice: t("notices.user_schedule_spots.created_partial", added: added, failed: failed)
    end
  end

  def create_from_schedule
    @schedule = current_user.schedules.find(params[:schedule_id])
    @schedule_spot = @schedule.schedule_spots.build(schedule_spot_params)
    @schedule_spot.day_number = 1
    if @schedule_spot.save
      respond_to do |format|
        format.turbo_stream { flash.now[:notice] = t("notices.schedule_spots.created") }
        format.html { redirect_to schedule_path(@schedule), notice: t("notices.schedule_spots.created") }
      end
    else
      set_categories
      render :new, status: :unprocessable_entity
    end
  end
end
