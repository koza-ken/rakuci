require 'rails_helper'

RSpec.describe 'Users::Schedules', type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:schedule) { create(:schedule, schedulable: user) }

  before { sign_in user }

  describe 'POST /schedules' do
    context '個人しおりを1件作成する場合' do
      let(:params) do
        {
          schedule: {
            name: 'テストしおり',
            start_date: '2026-01-10',
            end_date: '2026-01-15',
            memo: 'テスト用のメモです'
          }
        }
      end

      it 'しおりが1件作成されること' do
        expect {
          post schedules_path, params: params
        }.to change(Schedule, :count).by(1)
      end

      it 'しおり一覧ページにリダイレクトされること' do
        post schedules_path, params: params
        expect(response).to redirect_to(schedules_path)
      end

      it '成功メッセージが表示されること' do
        post schedules_path, params: params
        follow_redirect!
        expect(response.body).to include('しおりを作成しました')
      end

      it 'turbo_streamのレスポンスが返ること' do
        post schedules_path, params: params, as: :turbo_stream
        expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      end
    end

    context 'バリデーションエラーの場合' do
      let(:invalid_params) do
        {
          schedule: {
            name: '',  # 空文字列は無効
            start_date: '2026-01-10',
            end_date: '2026-01-15'
          }
        }
      end

      it 'しおりが作成されないこと' do
        expect {
          post schedules_path, params: invalid_params
        }.to change(Schedule, :count).by(0)
      end

      it '新規作成フォームが再表示されること' do
        post schedules_path, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context '終了日が開始日より前の場合' do
      let(:invalid_params) do
        {
          schedule: {
            name: 'テストしおり',
            start_date: '2026-01-15',
            end_date: '2026-01-10'  # 開始日より前
          }
        }
      end

      it 'しおりが作成されないこと' do
        expect {
          post schedules_path, params: invalid_params
        }.to change(Schedule, :count).by(0)
      end
    end

    context '未ログイン時' do
      before { sign_out user }

      it 'ログインページにリダイレクトされること' do
        post schedules_path, params: { schedule: { name: 'test' } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /schedules/:id' do
    it 'しおり詳細ページが表示されること' do
      get schedule_path(schedule)
      expect(response).to have_http_status(:success)
    end

    context '他人のしおりにアクセスする場合' do
      let(:other_schedule) { create(:schedule, schedulable: other_user) }

      it '404エラーが返ること' do
        get schedule_path(other_schedule)
        expect(response).to have_http_status(:not_found)
      end
    end

    context '未ログイン時' do
      before { sign_out user }

      it 'ログインページにリダイレクトされること' do
        get schedule_path(schedule)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /schedules/:id/edit' do
    it 'しおり編集フォームが表示されること' do
      get edit_schedule_path(schedule)
      expect(response).to have_http_status(:success)
    end

    context '他人のしおりを編集する場合' do
      let(:other_schedule) { create(:schedule, schedulable: other_user) }

      it '404エラーが返ること' do
        get edit_schedule_path(other_schedule)
        expect(response).to have_http_status(:not_found)
      end
    end

    context '未ログイン時' do
      before { sign_out user }

      it 'ログインページにリダイレクトされること' do
        get edit_schedule_path(schedule)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'PATCH /schedules/:id' do
    let(:params) do
      {
        schedule: {
          name: '更新後のしおり名',
          start_date: '2026-02-10',
          end_date: '2026-02-15',
          memo: '更新後のメモ'
        }
      }
    end

    it 'しおりが更新されること' do
      patch schedule_path(schedule), params: params
      schedule.reload
      expect(schedule.name).to eq('更新後のしおり名')
      expect(schedule.memo).to eq('更新後のメモ')
    end

    it 'しおり詳細ページにリダイレクトされること' do
      patch schedule_path(schedule), params: params
      expect(response).to redirect_to(schedule_path(schedule))
    end

    it '成功メッセージが表示されること' do
      patch schedule_path(schedule), params: params
      follow_redirect!
      expect(response.body).to include('しおりを更新しました')
    end

    context 'バリデーションエラーの場合' do
      let(:invalid_params) do
        {
          schedule: {
            name: '',  # 空文字列は無効
            start_date: '2026-01-10',
            end_date: '2026-01-15'
          }
        }
      end

      it 'しおりが更新されないこと' do
        original_name = schedule.name
        patch schedule_path(schedule), params: invalid_params
        schedule.reload
        expect(schedule.name).to eq(original_name)
      end

      it 'しおり編集フォームが再表示されること' do
        patch schedule_path(schedule), params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context '他人のしおりを更新する場合' do
      let(:other_schedule) { create(:schedule, schedulable: other_user) }

      it '404エラーが返ること' do
        patch schedule_path(other_schedule), params: params
        expect(response).to have_http_status(:not_found)
      end
    end

    context '未ログイン時' do
      before { sign_out user }

      it 'ログインページにリダイレクトされること' do
        patch schedule_path(schedule), params: params
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'DELETE /schedules/:id' do
    it 'しおりが削除されること' do
      schedule_id = schedule.id
      expect {
        delete schedule_path(schedule)
      }.to change(Schedule, :count).by(-1)
    end

    it 'しおり一覧ページにリダイレクトされること' do
      delete schedule_path(schedule)
      expect(response).to redirect_to(schedules_path)
    end

    it '削除メッセージが表示されること' do
      delete schedule_path(schedule)
      follow_redirect!
      expect(response.body).to include('しおりを削除しました')
    end

    context '他人のしおりを削除する場合' do
      let(:other_schedule) { create(:schedule, schedulable: other_user) }

      it '404エラーが返ること' do
        delete schedule_path(other_schedule)
        expect(response).to have_http_status(:not_found)
      end
    end

    context '未ログイン時' do
      before { sign_out user }

      it 'ログインページにリダイレクトされること' do
        delete schedule_path(schedule)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
