class Users::ScheduleSpotsController < ApplicationController
  before_action :authenticate_user!

  def show
    @schedule = current_user.schedules.find(params[:schedule_id])
    @schedule_spot = @schedule.schedule_spots.includes(:spot).find(params[:id])
  end

  def new
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

  def create
    @card = current_user.cards.find(params[:card_id])
    @schedule = current_user.schedules.find(params[:schedule_id])
    # spot_ids（複数）か spot_id（個別）かを判定
    spot_ids = params[:spot_ids].presence || [ params[:spot_id] ].compact
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
  end

  def destroy
    @schedule_spot = ScheduleSpot.find(params[:id])
    if @schedule_spot.destroy
      redirect_to schedule_path(current_user), notice: "スポットを削除しました", turbo: false
    end
  end
end
