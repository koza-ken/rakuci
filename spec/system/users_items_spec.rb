require "rails_helper"

RSpec.describe "個人用持ち物リスト管理", type: :system do
  let(:user) { create(:user) }
  let(:item_list) { user.item_list }

  before do
    login_as_user(user)
  end

  describe "アイテム追加" do
    it "新規アイテムを入力して送信すると、リストに追加されること" do
      visit item_list_path

      # ＋ボタンをクリックしてフォームを表示
      find("button[data-action='click->item-list-form#toggleForm']").click

      # フォームが表示されていることを確認
      expect(page).to have_field("item_name", visible: true)

      # 新しいアイテム名を入力
      fill_in "item_name", with: "パスポート"

      # 送信ボタンをクリック
      click_button I18n.t("item_lists.form.create_button")

      # Turbo Stream によりリストに追加されたことを確認
      expect(page).to have_content("パスポート")

      # フォーム値がリセットされていることを確認
      expect(page).to have_field("item_name", with: "", visible: false)

      # ページがリロードされていないことを確認
      expect(page).to have_current_path(item_list_path)
    end

    it "複数のアイテムを順番に追加できること" do
      visit item_list_path

      # 1つ目のアイテムを追加
      find("button[data-action='click->item-list-form#toggleForm']").click
      fill_in "item_name", with: "パスポート"
      click_button I18n.t("item_lists.form.create_button")
      expect(page).to have_content("パスポート")

      # 2つ目のアイテムを追加
      find("button[data-action='click->item-list-form#toggleForm']").click
      fill_in "item_name", with: "クレジットカード"
      click_button I18n.t("item_lists.form.create_button")
      expect(page).to have_content("クレジットカード")

      # 両方のアイテムが表示されていることを確認
      expect(page).to have_content("パスポート")
      expect(page).to have_content("クレジットカード")
    end

    it "空のアイテム名では追加できないこと（バリデーション）" do
      visit item_list_path

      # ＋ボタンをクリックしてフォームを表示
      find("button[data-action='click->item-list-form#toggleForm']").click

      # 空の名前で送信
      click_button I18n.t("item_lists.form.create_button")

      # ページがリロードされず、エラーメッセージが表示されることを確認
      expect(page).to have_current_path(item_list_path)
      # バリデーションエラーメッセージが表示される
      expect(page).to have_text("を入力してください")
    end
  end

  describe "アイテムのチェック状態" do
    let(:item) { create(:item, item_list: item_list, name: "パスポート") }

    before do
      item  # item を明示的に先に作成
    end

    it "チェックボックスをクリックすると、アイテム名に打消し線が入ること" do
      visit item_list_path

      # 初期状態：打消し線がない
      within("#item_#{item.id}") do
        expect(page).not_to have_css("span.line-through")
      end

      # チェックボックスをクリック
      check "item_#{item.id}_checked"

      # Stimulus により打消し線が表示されることを確認
      within("#item_#{item.id}") do
        expect(page).to have_css("span.line-through")
      end
    end

    it "チェックボックスを外すと、打消し線が消えること" do
      checked_item = create(:item, item_list: item_list, name: "パスポート", checked: true)

      visit item_list_path

      # 初期状態：打消し線がある
      within("#item_#{checked_item.id}") do
        expect(page).to have_css("span.line-through")
      end

      # チェックボックスを外す
      uncheck "item_#{checked_item.id}_checked"

      # Stimulus により打消し線が消えることを確認
      within("#item_#{checked_item.id}") do
        expect(page).not_to have_css("span.line-through")
      end
    end
  end

  describe "アイテム名編集" do
    let(:item) { create(:item, item_list: item_list, name: "パスポート") }

    before do
      item  # item を明示的に先に作成
    end

    it "アイテム名をクリックすると編集フォームが表示されること" do
      visit item_list_path

      # 初期状態：表示モード
      within("#item_#{item.id}") do
        expect(page).to have_text("パスポート")
      end

      # アイテム名をクリック
      find("#item_#{item.id}_display").click

      # 編集フォームが表示される（input要素がvisibleになる）
      within("#item_#{item.id}_form") do
        expect(page).to have_field(type: "text", with: "パスポート", visible: true)
      end
    end

it "編集モードで値を変更せずにblur（別の場所をクリックしてフォーカスが外れる）すると、フォームが閉じて変更なしであること" do
      visit item_list_path

      # アイテム名をクリックして編集モードに
      find("#item_#{item.id}_display").click

      input = find("#item_#{item.id}_form input[type='text']")
      # 値を変更しないで blur
      input.send_keys(:tab)

      # 表示モードに戻り、元の名前が保持されていることを確認
      within("#item_#{item.id}_display") do
        expect(page).to have_text("パスポート")
      end

      # 編集フォームが非表示になっていることを確認
      expect(page).not_to have_css("#item_#{item.id}_form", visible: true)
    end
  end

  describe "アイテム削除" do
    let(:item) { create(:item, item_list: item_list, name: "パスポート") }

    before do
      item  # item を明示的に先に作成
    end

    it "削除ボタンをクリックするとアイテムが削除されること" do
      visit item_list_path

      # アイテムが表示されていることを確認
      expect(page).to have_content("パスポート")

      # 削除ボタンをクリック（×ボタン）
      within("#item_#{item.id}") do
        find("button", text: "×").click
      end

      # Turbo Stream により削除されたことを確認
      expect(page).not_to have_content("パスポート")

      # ページがリロードされていないことを確認
      expect(page).to have_current_path(item_list_path)
    end

    it "複数のアイテムがある場合、選択したアイテムのみ削除されること" do
      item2 = create(:item, item_list: item_list, name: "クレジットカード")

      visit item_list_path

      # 両方のアイテムが表示されていることを確認
      expect(page).to have_content("パスポート")
      expect(page).to have_content("クレジットカード")

      # 最初のアイテムを削除
      within("#item_#{item.id}") do
        find("button", text: "×").click
      end

      # 最初のアイテムが削除され、2つ目は残っていることを確認
      expect(page).not_to have_content("パスポート")
      expect(page).to have_content("クレジットカード")
    end
  end
end
