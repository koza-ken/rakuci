require "rails_helper"

RSpec.describe "しおり作成フロー", type: :system do
  let(:user) { create(:user) }

  before do
    login_as_user(user)
  end

  describe "しおり作成画面でのモーダル表示とフォーム送信" do
    it "しおり作成リンククリックでモーダルが表示されること" do
      visit schedules_path

      # しおり作成リンククリック（Turbo Frameでモーダル表示）
      click_link I18n.t('users.schedules.index.create_schedule')

      # Turbo Frameの読み込みを待つ
      expect(page).to have_selector "turbo-frame#schedule-create-modal form"

      # モーダルが表示されていることを確認
      expect(page).to have_field "schedule_name"
      expect(page).to have_field "schedule_start_date"
      expect(page).to have_field "schedule_end_date"
    end

    it "しおり名と日付を入力してしおりを作成できること" do
      visit schedules_path

      # しおり作成リンククリック（Turbo Frameでモーダル表示）
      click_link I18n.t('users.schedules.index.create_schedule')

      # Turbo Frameの読み込みを待つ
      expect(page).to have_selector "turbo-frame#schedule-create-modal form"

      # フォームが表示されていることを確認
      expect(page).to have_field "schedule_name"
      expect(page).to have_field "schedule_start_date"
      expect(page).to have_field "schedule_end_date"

      # フォームに入力
      fill_in "schedule_name", with: "東京旅行"
      fill_in "schedule_start_date", with: "2026-02-01"
      fill_in "schedule_end_date", with: "2026-02-07"

      # 送信ボタンをクリック
      click_button I18n.t('schedules.form.submit')

      # しおりが作成され、一覧ページに戻されることを確認
      expect(page).to have_current_path(schedules_path)
      expect(page).to have_content("東京旅行")

      # DBに実際にしおりが作成されたか確認
      schedule = Schedule.last
      expect(schedule.name).to eq("東京旅行")
      expect(schedule.start_date).to eq(Date.parse("2026-02-01"))
      expect(schedule.end_date).to eq(Date.parse("2026-02-07"))
      expect(schedule.schedulable).to eq(user)
    end
  end

  describe "複数のしおりを順番に作成する" do
    it "複数のしおりを同じページで作成できること" do
      visit schedules_path

      # 1番目のしおりを追加
      click_link I18n.t('users.schedules.index.create_schedule')
      expect(page).to have_selector "turbo-frame#schedule-create-modal form"

      fill_in "schedule_name", with: "京都旅行"
      fill_in "schedule_start_date", with: "2026-03-01"
      fill_in "schedule_end_date", with: "2026-03-05"
      click_button I18n.t('schedules.form.submit')

      expect(page).to have_content("京都旅行")

      # 2番目のしおりを追加（FAB ボタンをクリック）
      # FABボタンが表示されるまで待機
      expect(page).to have_link(title: I18n.t('users.schedules.index.create_schedule'))
      click_link title: I18n.t('users.schedules.index.create_schedule')
      expect(page).to have_selector "turbo-frame#schedule-create-modal form"

      fill_in "schedule_name", with: "大阪旅行"
      fill_in "schedule_start_date", with: "2026-04-01"
      fill_in "schedule_end_date", with: "2026-04-03"
      click_button I18n.t('schedules.form.submit')

      expect(page).to have_content("大阪旅行")

      # ページ内に両方のしおりが存在することを確認
      expect(page).to have_content("京都旅行")
      expect(page).to have_content("大阪旅行")

      # DBに2件のしおりが作成されたことを確認
      expect(user.schedules.count).to eq(2)
      expect(user.schedules.map(&:name)).to contain_exactly("京都旅行", "大阪旅行")
    end
  end

  describe "バリデーションエラー確認" do
    it "終了日が開始日より前の場合、エラーが表示されること" do
      visit schedules_path

      # しおり作成リンククリック
      click_link I18n.t('users.schedules.index.create_schedule')
      expect(page).to have_selector "turbo-frame#schedule-create-modal form"

      # エラーが発生するデータを入力
      fill_in "schedule_name", with: "テストしおり"
      fill_in "schedule_start_date", with: "2026-02-07"
      fill_in "schedule_end_date", with: "2026-02-01"  # 開始日より前

      # 送信ボタンをクリック
      click_button I18n.t('schedules.form.submit')

      # エラーメッセージが表示されることを確認
      expect(page).to have_content("旅行終了日は旅行開始日より後の日付を設定してください")

      # DBに新しいScheduleが作成されていないことを確認
      expect(Schedule.count).to eq(0)
    end
  end
end
