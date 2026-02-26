module SchedulesHelper
  # しおりの詳細ページへのパスを返す
  # 個人しおりはresources（複数形）なのでscheduleのIDが必要
  # グループしおりはresource（単数形）なのでscheduleのIDは不要、代わりにGroupオブジェクトを渡す
  def schedule_show_path(schedule)
    if schedule.user_schedule?
      schedule_path(schedule)
    else
      group_schedule_path(schedule.schedulable)
    end
  end
end
