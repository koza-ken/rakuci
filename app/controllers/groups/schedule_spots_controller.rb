class Groups::ScheduleSpotsController < ApplicationController
  before_action :set_group
  before_action :check_group_member

  def show
    @schedule = @group.schedule
    @schedule_spot = @schedule.schedule_spots.includes(:spot).find(params[:id])
  end

  def create
    @card = Card.find(params[:card_id])
    @schedule = @group.schedule
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
      redirect_to card_path(@card), notice: "#{results.size}件のスポットをグループのしおりに追加しました", turbo: false
    elsif results.none?
      redirect_to card_path(@card), alert: "スポット追加に失敗しました", turbo: false
    else
      added = results.count(true)
      failed = results.count(false)
      redirect_to card_path(@card), notice: "#{added}件追加しました。#{failed}件失敗しました", turbo: false
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
