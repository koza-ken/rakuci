class Groups::ScheduleSpotsController < ApplicationController
  include GroupMemberAuthorization  # グループメンバーのみアクセス許可

  before_action :set_schedule_spot, only: %i[show edit update destroy move_higher move_lower]
  before_action :set_group, only: %i[new create]
  before_action :set_group_from_schedule_spot, only: %i[show edit update destroy move_higher move_lower]
  before_action :set_schedule
  before_action :check_group_member

  def show
    @category = Category.find_by(id: @schedule_spot.category_id)
  end

  def new
    @schedule_spot = ScheduleSpot.new
    set_categories
  end

  def create
    if params[:spot_ids].present? || params[:spot_id].present?
      # カードからスポット選択してしおり追加
      @card = Card.find(params[:card_id])
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
        respond_to do |format|
          format.turbo_stream { flash.now[:notice] = t("notices.group_schedule_spots.created_multiple", count: results.size) }
          format.html { redirect_to group_card_path(@group, @card), notice: t("notices.group_schedule_spots.created_multiple", count: results.size) }
        end
      elsif results.none?
        # 全て失敗
        respond_to do |format|
          format.turbo_stream { flash.now[:alert] = t("errors.group_schedule_spots.create_failed") }
          format.html { redirect_to group_card_path(@group, @card), alert: t("errors.group_schedule_spots.create_failed") }
        end
      else
        # 一部成功
        added = results.count(true)
        failed = results.count(false)
        respond_to do |format|
          format.turbo_stream { flash.now[:notice] = t("notices.group_schedule_spots.created_partial", added: added, failed: failed) }
          format.html { redirect_to group_card_path(@group, @card), notice: t("notices.group_schedule_spots.created_partial", added: added, failed: failed) }
        end
      end
    else
      # しおり詳細から直接スポット追加
      @schedule_spot = @schedule.schedule_spots.build(schedule_spot_params)
      @schedule_spot.day_number = 1

      if @schedule_spot.save
        respond_to do |format|
          format.turbo_stream { flash.now[:notice] = t("notices.schedule_spots.created") }
          format.html { redirect_to group_schedule_path(@group), notice: t("notices.schedule_spots.created") }
        end
      else
        set_categories
        render :new, status: :unprocessable_entity
      end
    end
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
        format.html { redirect_to group_schedule_spot_path(@schedule_spot), notice: t("notices.schedule_spots.updated") }
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @schedule_spot.destroy
      redirect_to group_schedule_path(@group), notice: t("notices.schedule_spots.destroyed"), turbo: false
    end
  end

  # 並び替えacts_as_listのメソッド
  def move_higher
    @schedule_spot.move_higher
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to group_schedule_path(@group) }
    end
  end

  def move_lower
    @schedule_spot.move_lower
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to group_schedule_path(@group) }
    end
  end

  private

  def set_schedule_spot
    @schedule_spot = ScheduleSpot.includes(:spot).find(params[:id])
  end

  def set_group
    @group = Group.find(params[:group_id])
  end

  def set_group_from_schedule_spot
    @group = @schedule_spot.schedule.schedulable
  end

  def set_schedule
    @schedule = @group.schedule
  end

  def set_categories
    @categories = Category.order(display_order: :asc).to_a
  end

  def schedule_spot_params
    params.require(:schedule_spot).permit(:name, :category_id, :address, :phone_number, :website_url, :google_place_id, :start_time, :end_time, :memo, :day_number, :global_position)
  end
end
