class Groups::SchedulesController < ApplicationController
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
      redirect_to group_path(@group), notice: t("notices.schedules.updated")
    else
      if from_page == "edit"
        render :edit, status: :unprocessable_entity
      else
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
