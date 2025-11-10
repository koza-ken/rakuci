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
end
