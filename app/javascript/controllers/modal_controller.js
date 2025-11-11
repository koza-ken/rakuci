import { Controller } from "@hotwired/stimulus"

// モーダルの制御
export default class extends Controller {
  // float action button
  static targets = [ "fab" ]

  // リンクをクリックしたときにgroup_idを保存
  setGroupId(event) {
    const groupId = event.currentTarget.dataset.groupId
    if (groupId) {
      sessionStorage.setItem('cardGroupId', groupId)
    } else {
      sessionStorage.removeItem('cardGroupId')
    }

    // FABボタンに .active クラスを付ける
    if (this.hasFabTarget) {
      this.fabTarget.classList.add("active")
    }
  }

  // connectは、このmodalコントローラがHTML（/groups/showと/cards/index）にアタッチされたときに一度実行されるメソッド
  // モーダルが開いたとき（Turbo Frameで内容が読み込まれたとき）
  connect() {
    // Turbo Frameの読み込み完了を待つ
    this.element.addEventListener('turbo:frame-load', () => {
      // turbo-frameが更新されてから（2回目）
      this.setGroupIdToForm()
    })

    // すでに読み込まれている場合のために即座にも実行（1回目：turbo-frameが空かもしれない）
    this.setGroupIdToForm()
  }

  // フォームのhidden fieldにgroup_idを設定
  setGroupIdToForm() {
    // sessionStorageからgroup_idを取得
    const groupId = sessionStorage.getItem('cardGroupId')

    if (groupId) {
      const hiddenField = this.element.querySelector('input[name="card[group_id]"]')

      if (hiddenField) {
        hiddenField.value = groupId
      }
    }
  }

  // 背景クリックでモーダルを閉じる
  close() {
    // Turbo Frameの中身を空にしてモーダルを非表示
    // remove()だとTurbo Frameごと削除されて2回目以降表示されなくなる
    this.element.innerHTML = ""

    // FABボタンの .active クラスを削除（全ページから探索）
    const fabButton = document.querySelector('[data-modal-target="fab"]')
    if (fabButton) {
      fabButton.classList.remove("active")
    }
  }
}
