// Sortable.jsでスポットを並び替えるコントローラー

import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

export default class extends Controller {
  connect() {
    const dayLists = document.querySelectorAll(".sortable-day-list")

    dayLists.forEach((list) => {
      new Sortable(list, {
        group: `schedule-spots-${list.dataset.scheduleId}`,
        animation: 150,
        ghostClass: "sortable-ghost",
        onEnd: (evt) => this.handleSortEnd(evt), // ドロップしたら発火するコールバック関数を定義
      })
    })
  }

  // ドロップしたときに実行される関数
  handleSortEnd(evt) {
    const item = evt.item
    const spotId = item.dataset.spotId
    const newDayNumber = parseInt(item.parentElement.dataset.dayNumber)
    const scheduleId = item.parentElement.dataset.scheduleId
    const newGlobalPosition = Array.from(item.parentElement.children).indexOf(item) + 1

    // バックエンドに更新を送信
    this.updateSpotPosition(scheduleId, spotId, newDayNumber, newGlobalPosition)
  }

  updateSpotPosition(scheduleId, spotId, dayNumber, globalPosition) {
    // groupIdがあればgroups用、なければusers用
    const groupId = this.element.dataset.groupId
    const url = groupId
      ? `/groups/${groupId}/schedule/schedule_spots/${spotId}`
      : `/schedules/${scheduleId}/schedule_spots/${spotId}`

    const params = {
      schedule_spot: {
        day_number: dayNumber,
        global_position: globalPosition,
      },
    }

    fetch(url, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
      },
      body: JSON.stringify(params),
    }).catch((error) => console.error("Error updating spot position:", error))
  }
}
