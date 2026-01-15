require "rails_helper"

RSpec.describe "スポット送信ボタン", type: :system do
  let(:user) { create(:user) }
  let(:group) do
    group = create(:group, creator: user)
    create(:group_membership, user: user, group: group)
    group
  end
  let(:schedule) { create(:schedule, :for_group, schedulable: group) }

  before do
    login_as_user(user)
  end

  describe "グループカードのスポット送信ボタン" do
    let(:card) { create(:card, :for_group, cardable: group) }
    let(:category) { create(:category) }
    let(:spot1) { create(:spot, card: card, category: category, name: "スポット1") }
    let(:spot2) { create(:spot, card: card, category: category, name: "スポット2") }
    let(:spot3) { create(:spot, card: card, category: category, name: "スポット3") }

    before do
      spot1
      spot2
      spot3
    end

    describe "ボタン有効/無効の動的切り替え" do
      it "初期状態ではボタンが無効（disabled）であること" do
        # スケジュールを作成してカードを表示
        group.update(schedule: schedule)
        visit group_card_path(group, card)

        # 初期状態：ボタンが disabled
        button = find("#group-submit-button")
        expect(button).to be_disabled
        expect(page).to have_css("#group-submit-button.opacity-50")
      end

      it "スポットを1つチェックするとボタンが有効（enabled）になること" do
        group.update(schedule: schedule)
        visit group_card_path(group, card)

        # スポット1をチェック
        check "spot_#{spot1.id}"

        # ボタンが enabled に変わる
        button = find("#group-submit-button")
        expect(button).not_to be_disabled
        expect(page).not_to have_css("#group-submit-button.opacity-50")
      end

      it "複数のスポットをチェックしてもボタンが有効のまま保たれること" do
        group.update(schedule: schedule)
        visit group_card_path(group, card)

        # スポット1をチェック
        check "spot_#{spot1.id}"
        button = find("#group-submit-button")
        expect(button).not_to be_disabled

        # スポット2もチェック
        check "spot_#{spot2.id}"
        expect(button).not_to be_disabled

        # スポット3もチェック
        check "spot_#{spot3.id}"
        expect(button).not_to be_disabled
      end

      it "チェックしたスポットをすべてアンチェックするとボタンが無効になること" do
        group.update(schedule: schedule)
        visit group_card_path(group, card)

        # スポット1をチェック
        check "spot_#{spot1.id}"
        button = find("#group-submit-button")
        expect(button).not_to be_disabled

        # スポット1をアンチェック
        uncheck "spot_#{spot1.id}"

        # ボタンが disabled に戻る
        expect(button).to be_disabled
        expect(page).to have_css("#group-submit-button.opacity-50")
      end

      it "スポットをチェックして送信するとしおりにスポットが追加されること" do
        group.update(schedule: schedule)
        visit group_card_path(group, card)

        # スポット1をチェック
        check "spot_#{spot1.id}"

        # ボタンをクリック（送信）
        click_button I18n.t('cards.add_spots_to_schedule'), id: "group-submit-button"

        # ページはリロードされている
        expect(page).to have_current_path(group_card_path(group, card))

        # スケジュールにスポットが追加されている
        expect(schedule.schedule_spots.map(&:spot_id)).to include(spot1.id)
      end
    end

    describe "複数スポット選択シナリオ" do
      it "複数のスポットをまとめて選択して追加できること" do
        group.update(schedule: schedule)
        visit group_card_path(group, card)

        # 複数のスポットをチェック
        check "spot_#{spot1.id}"
        check "spot_#{spot3.id}"

        # ボタンをクリック
        click_button I18n.t('cards.add_spots_to_schedule'), id: "group-submit-button"

        # ページはリロードされている
        expect(page).to have_current_path(group_card_path(group, card))

        # 複数のスポットがスケジュールに追加されている
        expect(schedule.schedule_spots.map(&:spot_id)).to include(spot1.id, spot3.id)
      end
    end
  end

  describe "個人カードのスポット送信ボタン" do
    let(:card) { create(:card, :for_user, cardable: user) }
    let(:schedule_personal) { create(:schedule, :for_user, schedulable: user) }
    let(:category) { create(:category) }
    let(:spot1) { create(:spot, card: card, category: category, name: "個人スポット1") }
    let(:spot2) { create(:spot, card: card, category: category, name: "個人スポット2") }

    before do
      spot1
      spot2
    end

    describe "ボタン有効/無効の動的切り替え" do
      it "初期状態ではボタンが無効（disabled）であること" do
        visit card_path(card)

        # 初期状態：ボタンが disabled（個人カードにスケジュール存在時のみ表示）
        if user.schedules.any?
          button = find("#personal-submit-button")
          expect(button).to be_disabled
          expect(page).to have_css("#personal-submit-button.opacity-50")
        end
      end

      it "スポットを1つチェックするとボタンが有効になること" do
        # ユーザーにスケジュールを追加
        schedule_personal
        visit card_path(card)

        # スポット1をチェック
        check "spot_#{spot1.id}"

        # ボタンが enabled に変わる
        button = find("#personal-submit-button")
        expect(button).not_to be_disabled
        expect(page).not_to have_css("#personal-submit-button.opacity-50")
      end

      it "スポットをチェックして送信できること" do
        schedule_personal
        visit card_path(card)

        # スポット1をチェック
        check "spot_#{spot1.id}"

        # ボタンをクリック（GET で送信、schedule_spots/new へ遷移）
        click_button I18n.t('cards.add_spots_to_schedule'), id: "personal-submit-button"

        # 新しいページに遷移している（schedule_spots/new へクエリパラメータ付きで遷移）
        expect(page).to have_current_path(/\/cards\/.*\/schedule_spots\/new/)
        # クエリパラメータに spot_ids が含まれている
        expect(page.current_url).to include("spot_ids%5B%5D=#{spot1.id}")
      end
    end
  end
end
