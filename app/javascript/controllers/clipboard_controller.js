import { Controller } from "@hotwired/stimulus"

// クリップボードコピー機能
export default class extends Controller {
  static values = {
    text: String  // コピーするテキスト
  }

  // 招待用URLをコピーするメソッド
  copy() {
    // Clipboard APIを使ってコピー
    navigator.clipboard.writeText(this.textValue)
      .then(() => {
        // コピー成功
        this.showToast("招待URLを共有しよう", "success")
      })
      // .catch(() => {
      //   // コピー失敗時のフォールバック処理
      //   if (this.fallbackCopy()) {
      //     this.showToast("コピーしました！", "success")
      //   } else {
      //     this.showToast("コピーに失敗しました", "error")
      //   }
      // })
  }

  // トースト通知を表示するメソッド
  showToast(message, type = "success") {
    // トースト要素を作成
    const toast = document.createElement("div")
    toast.textContent = message

    // スタイルを設定（Tailwind CSS）
    const baseClasses = "fixed top-4 left-1/2 -translate-x-1/2 px-6 py-3 rounded-lg shadow-lg text-white font-medium transition-opacity duration-300 z-50"
    const typeClasses = type === "success" ? "bg-green-600" : "bg-red-600"
    toast.className = `${baseClasses} ${typeClasses}`

    // DOMに追加
    document.body.appendChild(toast)

    // フェードイン
    setTimeout(() => {
      toast.style.opacity = "1"
    }, 10)

    // 2秒後にフェードアウトして削除
    setTimeout(() => {
      toast.style.opacity = "0"
      setTimeout(() => {
        toast.remove()
      }, 300)
    }, 2000)
  }

  // フォールバック処理（古いブラウザ用）
  // fallbackCopy() {
  //   const textarea = document.createElement("textarea")
  //   textarea.value = this.textValue
  //   textarea.style.position = "fixed"
  //   textarea.style.opacity = "0"
  //   document.body.appendChild(textarea)
  //   textarea.select()

  //   let success = false
  //   try {
  //     success = document.execCommand("copy")
  //   } catch (err) {
  //     success = false
  //   }

  //   document.body.removeChild(textarea)
  //   return success
  // }
}
