class Users::SchedulesController < ApplicationController
before_action :authenticate_user!

  def index
    @user = current_user
    @schedules = @user.schedules
  end

  def show
    @user = current_user
    @schedule = @user.schedules.find(params[:id])
  end
end
