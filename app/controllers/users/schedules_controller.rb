class Users::SchedulesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_schedule, only: %i[show edit update destroy]

  def index
    user_schedules = current_user.schedules
    group_schedule_ids = current_user.groups.pluck(:id)
    group_schedules = Schedule.where(schedulable_type: "Group", schedulable_id: group_schedule_ids).includes(schedulable: :group_memberships)
    @schedules = (user_schedules + group_schedules).sort_by { |s| s.start_date.presence || Date.new(1, 1, 1) }.reverse
  end

  def show
  end

  def new
    @schedule = current_user.schedules.build
  end

  def create
    @schedule = current_user.schedules.build(schedule_params)

    if @schedule.save
      respond_to do |format|
        format.turbo_stream { flash.now[:notice] = t("notices.schedules.created") }
        format.html { redirect_to schedules_path, notice: t("notices.schedules.created") }
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @schedule.update(schedule_params)
      redirect_to schedule_path(@schedule), notice: t("notices.schedules.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @schedule.destroy
      redirect_to schedules_path, notice: t("notices.schedules.destroyed"), turbo: false
    end
  end

  private

  def set_schedule
    @schedule = current_user.schedules.find(params[:id])
  end

  def schedule_params
    params.require(:schedule).permit(:name, :start_date, :end_date, :memo)
  end
end
