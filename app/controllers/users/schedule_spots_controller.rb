class Users::ScheduleSpotsController < ApplicationController
  before_action :authenticate_user!

  def show
    @schedule = current_user.schedules.find(params[:schedule_id])
    @schedule_spot = @schedule.schedule_spots.includes(:spot).find(params[:id])
  end

  # TODO でかそう
  def new
    if params[:schedule_id].present?
      # しおり詳細から直接スポット追加
      @schedule = current_user.schedules.find(params[:schedule_id])
      @schedule_spot = ScheduleSpot.new
      @categories = Category.all
    else
      # カードからスポット選択してしおり選択
      @card = current_user.cards.find(params[:card_id])
      if params[:spot_ids].present?
        # 複数スポット（チェックボックス）
        @spots = Spot.where(id: params[:spot_ids])
        @spot_ids = Array(params[:spot_ids])
      else
        # 単一スポット（個別追加）
        @spot = Spot.find(params[:id])
      end
      @schedules = current_user.schedules
    end
  end

  # TODO　でかそう
  def create
    if params[:spot_ids].present? || params[:spot_id].present?
      # カードからスポット選択してしおり選択
      @card = current_user.cards.find(params[:card_id])
      @schedule = current_user.schedules.find(params[:schedule_id])
      # spot_ids（複数）か spot_id（個別）かを判定
      spot_ids = params[:spot_ids].presence || [params[:spot_id]].compact
      # 複数作成
      results = spot_ids.map do |spot_id|
        spot = Spot.find(spot_id)
        schedule_spot = ScheduleSpot.create_from_spot(@schedule, spot)
        schedule_spot.save
      end
      # 成功・失敗を判定
      if results.all?
        redirect_to card_path(@card), notice: "#{results.size}件のスポットを追加しました"
      elsif results.none?
        # 全て失敗
        redirect_to card_path(@card), alert: "スポット追加に失敗しました"
      else
        # 一部成功
        added = results.count(true)
        failed = results.count(false)
        redirect_to card_path(@card), notice: "#{added}件追加しました。#{failed}件失敗しました"
      end
    else
      # しおり詳細から直接スポット追加
      @schedule = current_user.schedules.find(params[:schedule_id])
      @schedule_spot = @schedule.schedule_spots.build(schedule_spot_params)
      @schedule_spot.is_custom_entry = true
      @schedule_spot.day_number = 1
      @schedule_spot.global_position = (@schedule.schedule_spots.maximum(:global_position) || 0) + 1

      if @schedule_spot.save
        respond_to do |format|
          format.turbo_stream
          format.html { redirect_to schedule_path(@schedule), notice: "スポットを追加しました" }
        end
      else
        @categories = Category.all
        render :new, status: :unprocessable_entity
      end
    end
  end

  def edit
    @schedule = current_user.schedules.find(params[:schedule_id])
    @schedule_spot = @schedule.schedule_spots.includes(:spot).find(params[:id])
  end

  def update
    @schedule = current_user.schedules.find(params[:schedule_id])
    @schedule_spot = @schedule.schedule_spots.find(params[:id])
    if @schedule_spot.update(schedule_spot_params)
      redirect_to schedule_schedule_spot_path(@schedule, @schedule_spot), notice: "スポットを更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @schedule = current_user.schedules.find(params[:schedule_id])
    @schedule_spot = @schedule.schedule_spots.find(params[:id])
    if @schedule_spot.destroy
      redirect_to schedule_path(@schedule), notice: "スポットを削除しました", turbo: false
    end
  end

  private

  def schedule_spot_params
    params.require(:schedule_spot).permit(:snapshot_name, :snapshot_address, :snapshot_website_url, :snapshot_phone_number, :snapshot_category_id, :start_time, :end_time, :memo)
  end
end
