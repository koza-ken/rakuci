require "rails_helper"

RSpec.describe "グループ支出精算管理", type: :system do
  let(:group_creator) { create(:user) }
  let(:group_member1) { create(:user) }
  let(:group_member2) { create(:user) }
  let(:group) { create(:group, creator: group_creator) }
  let(:schedule) { create(:schedule, :for_group, schedulable: group) }

  before do
    schedule
    @membership_creator = group.group_memberships.create!(user: group_creator, group_nickname: "太郎")
    @membership_member1 = group.group_memberships.create!(user: group_member1, group_nickname: "花子")
    @membership_member2 = group.group_memberships.create!(user: group_member2, group_nickname: "次郎")
  end

  describe "複数支出追加時の精算額計算と表示" do
    before do
      login_as_user(group_creator)
    end

    it "2個の支出を追加すると、精算額が正しく計算・表示されること" do
      visit group_expenses_path(group)

      # 支出1：太郎が3000円を3人で割る
      select "太郎", from: "expense_paid_by_membership_id"
      fill_in "expense_name", with: "旅館代"
      fill_in "expense_amount", with: "3000"
      click_button I18n.t("expenses.add_button")

      # 支出1追加後の精算額確認
      expect(page).to have_text("太郎")
      expect(page).to have_text("+¥2,000")
      expect(page).to have_text("花子")
      expect(page).to have_text("-¥1,000")

      # 支出2：花子が600円を3人で割る
      select "花子", from: "expense_paid_by_membership_id"
      fill_in "expense_name", with: "夜間食事代"
      fill_in "expense_amount", with: "600"
      click_button I18n.t("expenses.add_button")

      # 支出2追加後の精算額確認（累積）
      # 太郎：paid=3000, participation=1200 → +1800
      # 花子：paid=600, participation=1200 → -600
      # 次郎：paid=0, participation=1200 → -1200
      expect(page).to have_text("+¥1,800")
      expect(page).to have_text("-¥600")
      expect(page).to have_text("-¥1,200")

      # 支出一覧に両方の支出が表示されていることを確認
      expect(page).to have_content("旅館代")
      expect(page).to have_content("夜間食事代")
    end
  end

  describe "支出編集時の精算額更新と表示" do
    before do
      @expense = create(:expense,
        group: group,
        paid_by_membership_id: @membership_creator.id,
        amount: 3000,
        name: "旅館代",
        expense_participants_list: [@membership_creator, @membership_member1, @membership_member2]
      )
      login_as_user(group_creator)
    end

    it "支出の金額を編集すると、精算額が再計算・再表示されること" do
      visit group_expenses_path(group)

      # 編集前：太郎 +2000
      expect(page).to have_text("+¥2,000")

      # 編集ボタンをクリック
      click_link "", href: edit_group_expense_path(group, @expense)

      # 金額を3000から6000に変更
      fill_in "expense_amount", with: "6000"
      click_button I18n.t("expenses.update_button")

      # 編集後：太郎 +4000
      expect(page).to have_text("+¥4,000")
      # 花子：-2000
      expect(page).to have_text("-¥2,000")
    end
  end

  describe "支出削除時の精算額更新と表示" do
    before do
      @expense1 = create(:expense,
        group: group,
        paid_by_membership_id: @membership_creator.id,
        amount: 3000,
        name: "旅館代",
        expense_participants_list: [@membership_creator, @membership_member1, @membership_member2]
      )
      @expense2 = create(:expense,
        group: group,
        paid_by_membership_id: @membership_member1.id,
        amount: 600,
        name: "夜間食事代",
        expense_participants_list: [@membership_creator, @membership_member1, @membership_member2]
      )
      login_as_user(group_creator)
    end

    it "支出を削除すると、精算額が更新・再表示されること" do
      visit group_expenses_path(group)

      # 削除前：太郎 +1800
      expect(page).to have_text("+¥1,800")

      # 支出1を削除
      within("div.border.border-gray-200", text: "旅館代") do
        page.accept_confirm do
          click_button ""
        end
      end

      # 削除後：太郎 -200（支出2の参加分のみ）
      expect(page).to have_text("-¥200")
      # 花子：+400
      expect(page).to have_text("+¥400")

      # 支出一覧に旅館代が表示されていないことを確認
      expect(page).not_to have_content("旅館代")
      expect(page).to have_content("夜間食事代")
    end
  end
end
