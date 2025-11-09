class Groups::ScheduleSpotsController < ApplicationController
  before_action :authenticate_user!

  def show
    @schedule = Schedule.find(params[:schedule_id])
    @schedule_spot = @schedule.schedule_spots.find(params[:id])
  end

  def create
    @card = Card.find(params[:card_id])
    @spot = Spot.find(params[:spot_id])
    @group = @card.group
    @schedule = Schedule.find_by(schedulable_id: @group.id)
    @schedule_spot = ScheduleSpot.create_from_spot(@schedule, @spot)

    if @schedule_spot.save
      redirect_to card_spot_path(@card, @spot), notice: "スポットをグループのしおりに追加しました"
    else
      redirect_to card_spot_path(@card, @spot), alert: "追加に失敗しました"
    end
  end

end
