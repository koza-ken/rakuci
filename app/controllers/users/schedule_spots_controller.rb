class Users::ScheduleSpotsController < ApplicationController
  before_action :authenticate_user!

  def show
    @schedule = current_user.schedules.find(params[:schedule_id])
    @schedule_spot = @schedule.schedule_spots.includes(:spot).find(params[:id])
  end

  def new
    @schedule = current_user.schedules.find(params[:schedule_id])
    @schedule_spot = ScheduleSpot.new
    @categories = Category.all
  end

  def create
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
