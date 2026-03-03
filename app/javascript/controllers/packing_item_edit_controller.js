import { Controller } from "@hotwired/stimulus"

// 持ち物の編集・チェック機能を制御
export default class extends Controller {
  static targets = ["display", "editForm", "checkbox", "nameInput", "itemRow"]

  // 元の値を保存（キャンセル時に復元）
  saveOriginalValue() {
    const input = this.editFormTarget.querySelector('input[type="text"]')
    if (input) {
      this.originalValue = input.value
    }
  }

  // 編集フォーム表示/非表示を切り替える
  toggleEditForm() {
    const isHidden = this.editFormTarget.classList.contains("hidden")

    if (isHidden) {
      // 編集フォーム非表示状態 → 表示に切り替え
      this.saveOriginalValue()
      this.displayTarget.classList.add("hidden")
      this.editFormTarget.classList.remove("hidden")
      // 入力フィールドにフォーカス
      this.nameInputTarget.focus()
      this.nameInputTarget.select()
    } else {
      // 編集フォーム表示状態 → 非表示に切り替え（キャンセル時）
      const input = this.editFormTarget.querySelector('input[type="text"]')
      // 元の値に復元
      if (input && this.originalValue !== undefined) {
        input.value = this.originalValue
      }
      this.editFormTarget.classList.add("hidden")
      this.displayTarget.classList.remove("hidden")
    }
  }

  // チェックボックス変更時の処理
  toggleCheck() {
    const isChecked = this.checkboxTarget.checked
    // 表示側の スタイルを更新（即座に反応）
    const displaySpan = this.displayTarget.querySelector("span")
    if (displaySpan) {
      if (isChecked) {
        displaySpan.classList.add("line-through", "opacity-50")
      } else {
        displaySpan.classList.remove("line-through", "opacity-50")
      }
    }

    // サーバーにAjaxでupdateリクエスト
    this.updateCheckStatus(isChecked)
  }

  // サーバーにcheckedステータスを送信
  updateCheckStatus(isChecked) {
    const itemRow = this.itemRowTarget
    const itemId = itemRow.id.replace("packing_item_", "")
    // URL は packing_list_item_path(packing_list, packing_item) => /packing_list/items/:id
    const url = `${window.location.pathname.replace(/\/packing_list.*/, "")}/packing_list/items/${itemId}`

    const params = {
      packing_item: {
        checked: isChecked,
      },
    }

    fetch(url, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
      },
      body: JSON.stringify(params),
    }).catch((error) => console.error("Error updating packing item:", error))
  }

  // blur時にアイテムを保存
  saveItem(event) {
    const input = event.target
    const itemId = this.itemRowTarget.id.replace("packing_item_", "")
    const newValue = input.value
    const originalValue = this.originalValue

    // 値が変わっていない場合はフォーム非表示にして終了
    if (newValue === originalValue) {
      this.editFormTarget.classList.add("hidden")
      this.displayTarget.classList.remove("hidden")
      return
    }

    // URL と params を構築
    const url = `${window.location.pathname.replace(/\/packing_list.*/, "")}/packing_list/items/${itemId}`
    const params = {
      packing_item: {
        name: newValue,
      },
    }

    fetch(url, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
      },
      body: JSON.stringify(params),
    })
      .then((response) => {
        if (response.ok) {
          // 表示側の text を更新
          const displaySpan = this.displayTarget.querySelector("span")
          if (displaySpan) {
            displaySpan.textContent = newValue
          }
          // フォーム非表示に
          this.editFormTarget.classList.add("hidden")
          this.displayTarget.classList.remove("hidden")
        } else {
          console.error("Error updating packing item:", response.status)
          // エラー時は元の値に戻す
          input.value = originalValue
        }
      })
      .catch((error) => {
        console.error("Error updating packing item:", error)
        // エラー時は元の値に戻す
        input.value = originalValue
      })
  }
}
