class Groups::ScheduleSpotsController < ApplicationController
  before_action :set_group
  before_action :check_group_member

  def show
    @schedule = @group.schedule
    @schedule_spot = @schedule.schedule_spots.includes(:spot).find(params[:id])
  end

  def new
    @schedule = @group.schedule
    @schedule_spot = ScheduleSpot.new
    @categories = Category.all
  end

  def create
    @schedule = @group.schedule

    # スポット詳細からの追加の場合
    if params[:spot_id].present?
      spot = Spot.find(params[:spot_id])
      @schedule_spot = @schedule.schedule_spots.build(
        spot: spot,
        snapshot_name: spot.name,
        snapshot_category_id: spot.category_id,
        snapshot_address: spot.address,
        snapshot_phone_number: spot.phone_number,
        snapshot_website_url: spot.website_url,
        google_place_id: spot.google_place_id,
        is_custom_entry: false,
        day_number: 1,
        global_position: (@schedule.schedule_spots.maximum(:global_position) || 0) + 1
      )
    else
      # 直接入力での追加の場合
      @schedule_spot = @schedule.schedule_spots.build(schedule_spot_params)
      @schedule_spot.is_custom_entry = true
      @schedule_spot.day_number = 1
      @schedule_spot.global_position = (@schedule.schedule_spots.maximum(:global_position) || 0) + 1
    end

    if @schedule_spot.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to group_schedule_path(@group), notice: "スポットを追加しました" }
      end
    else
      @categories = Category.all
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @schedule = @group.schedule
    @schedule_spot = @schedule.schedule_spots.includes(:spot).find(params[:id])
  end

  def update
    @schedule = @group.schedule
    @schedule_spot = @schedule.schedule_spots.find(params[:id])
    if @schedule_spot.update(schedule_spot_params)
      redirect_to group_schedule_schedule_spot_path(@group, @schedule_spot), notice: "スポットを更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @schedule_spot = ScheduleSpot.find(params[:id])
    if @schedule_spot.destroy
      redirect_to group_schedule_path(@group), notice: "スポットを削除しました", turbo: false
    end
  end

  private

  def set_group
    if params[:group_id].present?
      @group = Group.find(params[:group_id])
    elsif params[:card_id].present?
      # スポット詳細からの追加の場合、cardからgroupを取得
      card = Card.find(params[:card_id])
      @group = card.group
    end
  end

  def schedule_spot_params
    params.require(:schedule_spot).permit(:snapshot_name, :snapshot_category_id, :snapshot_address, :snapshot_phone_number, :snapshot_website_url, :google_place_id, :start_time, :end_time, :memo)
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
