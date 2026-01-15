require "rails_helper"

RSpec.describe "グループ用持ち物リスト管理", type: :system do
  let(:group_creator) { create(:user) }
  let(:group_member) { create(:user) }
  let(:non_member) { create(:user) }
  let(:group) { create(:group, creator: group_creator) }
  let(:schedule) { create(:schedule, :for_group, schedulable: group) }
  let(:item_list) { schedule.item_list }

  before do
    # グループメンバーシップを作成
    group.group_memberships.create!(user: group_creator, group_nickname: "作成者")
    group.group_memberships.create!(user: group_member, group_nickname: "メンバー")
  end

  describe "グループメンバーのアイテム追加（Turbo Stream）" do
    before do
      login_as_user(group_member)
    end

    it "グループメンバーが新規アイテムを追加できること" do
      visit group_schedule_item_list_path(group, schedule)

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
      expect(page).to have_current_path(group_schedule_item_list_path(group, schedule))
    end

    it "複数のアイテムを順番に追加できること" do
      visit group_schedule_item_list_path(group, schedule)

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
      visit group_schedule_item_list_path(group, schedule)

      # ＋ボタンをクリックしてフォームを表示
      find("button[data-action='click->item-list-form#toggleForm']").click

      # 空の名前で送信
      click_button I18n.t("item_lists.form.create_button")

      # ページがリロードされず、エラーメッセージが表示されることを確認
      expect(page).to have_current_path(group_schedule_item_list_path(group, schedule))
      # バリデーションエラーメッセージが表示される
      expect(page).to have_text("を入力してください")
    end
  end

  describe "グループメンバーのアイテムチェック状態（Stimulus）" do
    let(:item) { create(:item, item_list: item_list, name: "パスポート") }

    before do
      item  # item を明示的に先に作成
      login_as_user(group_member)
    end

    it "チェックボックスをクリックすると、アイテム名に打消し線が入ること" do
      visit group_schedule_item_list_path(group, schedule)

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

      visit group_schedule_item_list_path(group, schedule)

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

  describe "グループメンバーのアイテム削除（Turbo Stream）" do
    let(:item) { create(:item, item_list: item_list, name: "パスポート") }

    before do
      item  # item を明示的に先に作成
      login_as_user(group_member)
    end

    it "削除ボタンをクリックするとアイテムが削除されること" do
      visit group_schedule_item_list_path(group, schedule)

      # アイテムが表示されていることを確認
      expect(page).to have_content("パスポート")

      # 削除ボタンをクリック（×ボタン）
      within("#item_#{item.id}") do
        find("button", text: "×").click
      end

      # Turbo Stream により削除されたことを確認
      expect(page).not_to have_content("パスポート")

      # ページがリロードされていないことを確認
      expect(page).to have_current_path(group_schedule_item_list_path(group, schedule))
    end

    it "複数のアイテムがある場合、選択したアイテムのみ削除されること" do
      item2 = create(:item, item_list: item_list, name: "クレジットカード")

      visit group_schedule_item_list_path(group, schedule)

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

  describe "グループメンバーシップと権限" do
    let(:item) { create(:item, item_list: item_list, name: "パスポート") }

    before do
      item
    end

    it "グループメンバーはアイテムリストにアクセスできること" do
      login_as_user(group_member)
      visit group_schedule_item_list_path(group, schedule)

      expect(page).to have_current_path(group_schedule_item_list_path(group, schedule))
      expect(page).to have_content("パスポート")
    end

    it "グループ作成者もアイテムリストにアクセスできること" do
      login_as_user(group_creator)
      visit group_schedule_item_list_path(group, schedule)

      expect(page).to have_current_path(group_schedule_item_list_path(group, schedule))
      expect(page).to have_content("パスポート")
    end

    it "グループメンバーではないユーザーはアクセスできないこと" do
      login_as_user(non_member)
      visit group_schedule_item_list_path(group, schedule)

      # リダイレクトあるいいはアクセス拒否を確認
      expect(page).not_to have_current_path(group_schedule_item_list_path(group, schedule))
    end
  end
end
