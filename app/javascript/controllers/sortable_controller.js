// Sortable.jsでスポットを並び替えるコントローラー

import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

export default class extends Controller {
  connect() {
    this.initializeSortables()

    // Turbo Stream でスポット追加時に再初期化
    document.addEventListener("turbo:load", () => this.initializeSortables())
  }

  initializeSortables() {
    // スケジュール内のスポット並び替え
    const dayLists = document.querySelectorAll(".sortable-day-list")

    dayLists.forEach((list) => {
      new Sortable(list, {
        group: `schedule-spots-${list.dataset.scheduleId}`,
        animation: 150,
        ghostClass: "sortable-ghost",
        handle: ".drag-handle",
        onEnd: (evt) => this.handleSortEnd(evt),
      })
    })

    // もちものリストのアイテム並び替え
    const itemsLists = document.querySelectorAll("#items-list")

    itemsLists.forEach((list) => {
      new Sortable(list, {
        animation: 150,
        ghostClass: "sortable-ghost",
        // ドラッグのハンドルをクラスで指定
        handle: ".drag-handle",
        // items全体をグループと指定することで並び替えができる
        group: "items",
        onEnd: (evt) => this.handleItemsSortEnd(evt),
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
    const isGroup = this.element.dataset.groupId
    const url = isGroup
      ? `/group/schedule_spots/${spotId}`
      : `/user/schedule_spots/${spotId}`

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

  // もちものリストのアイテム並び替え後に実行
  handleItemsSortEnd(evt) {
    const item = evt.item
    const itemId = item.dataset.itemId
    const newPosition = evt.newIndex + 1

    // バックエンドに更新を送信
    this.updateItemPosition(itemId, newPosition)
  }

  updateItemPosition(itemId, position) {
    const url = `${window.location.pathname.replace(/\/item_list.*/, "")}/item_list/items/${itemId}`

    const params = {
      item: {
        position: position,
      },
    }

    fetch(url, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
      },
      body: JSON.stringify(params),
    }).catch((error) => console.error("Error updating item position:", error))
  }
}
