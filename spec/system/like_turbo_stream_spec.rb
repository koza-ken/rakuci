require "rails_helper"

RSpec.describe "Like Turbo Stream リアルタイム更新", type: :system do
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }
  let(:group) do
    group = create(:group, creator: user1)
    create(:group_membership, user: user1, group: group)
    create(:group_membership, user: user2, group: group)
    group
  end
  let(:card) { create(:card, :for_group, cardable: group, name: "グループカード") }

  before do
    login_as_user(user1)
  end

  describe "いいねボタン（Turbo Stream - replace）" do
    it "いいゼロ状態のボタンをクリックするとハートが赤くなり、カウントが増えること" do
      # カードが正しく group に関連付けられているか確認
      expect(card.cardable_id).to eq(group.id)
      expect(card.cardable_type).to eq("Group")

      visit group_path(group)
      expect(page).to have_content(group.name)

      # 初期状態：いいね数は0
      expect(page).to have_selector("div#like_area_#{card.id}")
      within("div#like_area_#{card.id}") do
        expect(page).to have_content("0")
      end

      # いいねボタンをクリック
      within("div#like_area_#{card.id}") do
        find_button(title: I18n.t("likes.add")).click
      end

      # Turbo Stream 完了を待つ：count が 1 に
      within("div#like_area_#{card.id}") do
        expect(page).to have_content("1")
      end

      # ページはリロードされていない
      expect(page).to have_current_path(group_path(group))

      # DB にいいねが作成されている
      expect(card.likes.count).to eq(1)
    end
  end

  describe "いいね削除" do
    it "いいね済みボタンをクリックするとハートが白くなり、カウントが減ること" do
      # 事前にいいね作成
      user1_membership = user1.group_memberships.find_by(group: group)
      create(:like, card: card, group_membership: user1_membership)

      visit group_path(group)
      expect(page).to have_content(group.name)

      # 初期状態：いいね数は1
      within("div#like_area_#{card.id}") do
        expect(page).to have_content("1")
      end

      # いいね削除ボタンをクリック
      within("div#like_area_#{card.id}") do
        find_button(title: I18n.t("likes.remove")).click
      end

      # Turbo Stream 完了を待つ：count が 0 に
      within("div#like_area_#{card.id}") do
        expect(page).to have_content("0")
      end

      # ページはリロードされていない
      expect(page).to have_current_path(group_path(group))

      # DB からいいねが削除されている
      expect(card.likes.count).to eq(0)
    end

    it "複数のいいねがある場合、自分のいいねだけ削除されること" do
      user1_membership = user1.group_memberships.find_by(group: group)
      user2_membership = user2.group_memberships.find_by(group: group)
      create(:like, card: card, group_membership: user1_membership)
      create(:like, card: card, group_membership: user2_membership)

      visit group_path(group)
      expect(page).to have_content(group.name)

      # 初期状態：count が 2
      within("div#like_area_#{card.id}") do
        expect(page).to have_content("2")
      end

      # user1 がいいね削除
      within("div#like_area_#{card.id}") do
        find_button(title: I18n.t("likes.remove")).click
      end

      # Turbo Stream 完了を待つ：count が 1 に
      within("div#like_area_#{card.id}") do
        expect(page).to have_content("1")
      end

      # DB には user2 のいいねだけ残っている
      expect(card.likes.count).to eq(1)
      expect(card.likes.first.group_membership.user_id).to eq(user2.id)
    end
  end

  describe "いいねのバリデーション" do
    it "同じユーザーが重複いいねできないこと" do
      user1_membership = user1.group_memberships.find_by(group: group)
      create(:like, card: card, group_membership: user1_membership)

      visit group_path(group)
      expect(page).to have_content(group.name)

      # いいね済み（赤いハート）をクリックして削除
      within("div#like_area_#{card.id}") do
        find_button(title: I18n.t("likes.remove")).click
      end

      # いいねが削除される
      within("div#like_area_#{card.id}") do
        expect(page).to have_content("0")
      end

      # もう一度いいねをクリック（追加）
      within("div#like_area_#{card.id}") do
        find_button(title: I18n.t("likes.add")).click
      end

      # いいねが追加される（重複ではなく、新規作成）
      within("div#like_area_#{card.id}") do
        expect(page).to have_content("1")
      end

      # DB には1件だけ保存されている
      expect(card.likes.count).to eq(1)
    end
  end
end
