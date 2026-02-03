class Groups::SchedulesController < ApplicationController
  include GroupMemberAuthorization  # グループメンバーのみアクセス許可

  before_action :set_group
  before_action :check_group_member

  def show
    # groupには一つしかscheduleがない
    @schedule = @group.schedule
  end

  def new
    @schedule = @group.build_schedule
  end

  def create
    @schedule = @group.build_schedule(schedule_params)

    if @schedule.save
      respond_to do |format|
        format.turbo_stream { flash.now[:notice] = t("notices.schedules.created") }
        format.html { redirect_to group_path(@group), notice: t("notices.schedules.created") }
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @schedule = @group.schedule
  end

  def update
    @schedule = @group.schedule
    from_page = params[:schedule][:from_page]

    if @schedule.update(schedule_params)
      # from_page パラメータに基づいて遷移先を分岐
      if from_page == "show"
        redirect_to group_path(@group), notice: t("notices.schedules.updated")
      else
        redirect_to group_schedule_path(@group), notice: t("notices.schedules.updated")
      end
    else
      if from_page == "edit"
        render :edit, status: :unprocessable_entity
      else
        @cards_with_spots_by_category = @group.cards_with_spots_grouped
        render template: "groups/show", layout: "application", status: :unprocessable_entity, locals: { group: @group, schedule: @schedule }
      end
    end
  end

  private

  def set_group
    @group = Group.find(params[:group_id])
  end

  def schedule_params
    params.require(:schedule).permit(:name, :start_date, :end_date, :memo)
  end

end
