class Users::ScheduleSpotsController < ApplicationController
  before_action :authenticate_user!

  def show
    @schedule = current_user.schedules.find(params[:schedule_id])
    @schedule_spot = @schedule.schedule_spots.find(params[:id])
  end

  def new
    @card = current_user.cards.find(params[:card_id])
    @spot = Spot.find(params[:spot_id])
    @schedules = current_user.schedules
  end

  def create
    @card = current_user.cards.find(params[:card_id])
    @spot = Spot.find(params[:spot_id])
    @schedule = current_user.schedules.find(params[:schedule_id])
    @schedule_spot = ScheduleSpot.create_from_spot(@schedule, @spot)

    if @schedule_spot.save
      redirect_to card_spot_path(@card, @spot), notice: "スポットをしおりに追加しました"
    else
      @schedules = current_user.schedules
      render :new, status: :unprocessable_entity
    end
  end
end
