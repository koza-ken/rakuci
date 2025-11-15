import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["autocomplete", "nameField", "addressField", "websiteField", "phoneField", "idField", "errorMessage"]

  // コントローラがHTMLに接続されたときに実行
  connect() {
    this.waitForGoogle()
  }

  // Google Maps API の読み込みを待つ
  waitForGoogle() {
    if (typeof google !== 'undefined') {
      this.initAutocomplete()
    } else {
      setTimeout(() => this.waitForGoogle(), 100)
    }
  }

  initAutocomplete() {
    // gmp-place-autocomplete 要素を取得
    const autocompleteElement = this.autocompleteTarget

    // 場所が選択されたときの処理
    autocompleteElement.addEventListener('gmp-select', async ({ placePrediction }) => {
      if (!placePrediction) {
        this.showError()
        return
      }

      try {
        // PlacePrediction を Place オブジェクトに変換
        const place = await placePrediction.toPlace();

        await place.fetchFields({
          fields: [
            "displayName",
            "formattedAddress",
            "internationalPhoneNumber",
            "websiteURI",
            "id",
          ],
        });

        // 取得したデータを加工
        const name = place.displayName || "";
        const address = this.formatAddress(place.formattedAddress || "");
        const phone = this.formatPhoneNumber(
          place.internationalPhoneNumber || ""
        );
        const website = place.websiteURI || "";
        const google_place_id = place.id || "";

        // フォームに自動入力
        this.nameFieldTarget.value = name;
        this.addressFieldTarget.value = address;
        this.phoneFieldTarget.value = phone;
        this.websiteFieldTarget.value = website;
        this.idFieldTarget.value = google_place_id;

        // オートコンプリート入力欄を施設名に更新
        const inputElement = autocompleteElement.querySelector("input");
        if (inputElement) {
          inputElement.value = name;
        }

        // エラーメッセージを非表示
        this.hideError()
      } catch (error) {
        this.showError()
      }
    })
  }

  // 住所を整形（「日本、」と郵便番号を削除）
  formatAddress(address) {
    // 「日本、」を削除
    let formatted = address.replace(/^日本、\s*/, '')

    // 郵便番号（〒xxx-xxxx または 〒xxxxxxx）を削除
    formatted = formatted.replace(/〒\d{3}-?\d{4}\s*/, '')

    return formatted
  }

  // 電話番号を整形（+81 → 0）
  formatPhoneNumber(phone) {
    // +81 を 0 に変換し、スペースを削除
    // 例: "+81 3-3433-5111" → "03-3433-5111"
    return phone.replace(/^\+81\s*/, '0').replace(/\s+/g, '')
  }

  // エラーメッセージを表示
  showError() {
    this.errorMessageTarget.classList.remove('hidden')
  }

  // エラーメッセージを非表示
  hideError() {
    this.errorMessageTarget.classList.add('hidden')
  }
}
