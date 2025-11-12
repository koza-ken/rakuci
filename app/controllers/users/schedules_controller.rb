class Users::SchedulesController < ApplicationController
  before_action :authenticate_user!

  def index
    @user = current_user
    personal_schedules = @user.schedules
    group_schedules = @user.groups.map(&:schedule).compact
    @schedules = (personal_schedules + group_schedules).sort_by { |s| s.start_date.presence || Date.new(1, 1, 1) }.reverse
  end

  def show
    @user = current_user
    @schedule = @user.schedules.find(params[:id])
  end

  def new
    @schedule = current_user.schedules.build
  end

  def create
    @schedule = current_user.schedules.build(schedule_params)

    if @schedule.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to schedules_path, notice: t("notices.schedules.created") }
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def schedule_params
    params.require(:schedule).permit(:name, :start_date, :end_date)
  end
end
