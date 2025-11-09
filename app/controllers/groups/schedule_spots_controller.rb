class Groups::ScheduleSpotsController < ApplicationController
  before_action :set_group
  before_action :check_group_member

  def show
    @schedule = @group.schedule
    @schedule_spot = @schedule.schedule_spots.find(params[:id])
  end

  def create
    @card = Card.find(params[:card_id])
    @spot = Spot.find(params[:spot_id])
    @schedule = @group.schedule
    @schedule_spot = ScheduleSpot.create_from_spot(@schedule, @spot)

    if @schedule_spot.save
      redirect_to card_spot_path(@card, @spot), notice: "スポットをグループのしおりに追加しました"
    else
      redirect_to card_spot_path(@card, @spot), alert: "追加に失敗しました"
    end
  end

  private

  def set_group
    if params[:group_id]
      # showアクション: URLから直接group_idを取得
      @group = Group.find(params[:group_id])
    elsif params[:card_id]
      # createアクション: cardからgroupを取得
      card = Card.find(params[:card_id])
      @group = card.group
    end
  end

  # グループに参加しているか確認するフィルター（showアクションのフィルター）
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
