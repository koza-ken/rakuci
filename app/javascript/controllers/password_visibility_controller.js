import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "showIcon", "hideIcon"]

  toggle() {
    const isPassword = this.inputTarget.type === "password"
    this.inputTarget.type = isPassword ? "text" : "password"
    // 第2引数を渡すとTargetの状態によらずにhiddenのありなしを操作できる
    this.showIconTarget.classList.toggle("hidden", isPassword)  // isPasswordがtrue（inputがpassword）ならshowIconクリックするとhiddenをつける
    this.hideIconTarget.classList.toggle("hidden", !isPassword)
  }
}
