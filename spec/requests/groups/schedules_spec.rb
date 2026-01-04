require 'rails_helper'

RSpec.describe 'Groups::Schedules', type: :request do
  let(:user) { create(:user) }
  let(:group) do
    group = create(:group, created_by_user_id: user.id)
    create(:group_membership, group: group, user: user)
    group
  end
  let(:other_user) { create(:user) }
  let(:other_group) do
    group = create(:group, created_by_user_id: other_user.id)
    create(:group_membership, group: group, user: other_user)
    group
  end
  let!(:group_schedule) { create(:schedule, schedulable: group) }

  before { sign_in user }

  describe 'POST /groups/:group_id/schedule' do
    context 'グループしおりを作成する場合' do
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
        group_without_schedule = create(:group, created_by_user_id: user.id)
        create(:group_membership, group: group_without_schedule, user: user)

        expect {
          post group_schedule_path(group_without_schedule), params: params
        }.to change(Schedule, :count).by(1)
      end

      it 'グループ詳細ページにリダイレクトされること' do
        group_without_schedule = create(:group, created_by_user_id: user.id)
        create(:group_membership, group: group_without_schedule, user: user)

        post group_schedule_path(group_without_schedule), params: params
        expect(response).to redirect_to(group_path(group_without_schedule))
      end

      it 'turbo_streamのレスポンスが返ること' do
        group_without_schedule = create(:group, created_by_user_id: user.id)
        create(:group_membership, group: group_without_schedule, user: user)

        post group_schedule_path(group_without_schedule), params: params, as: :turbo_stream
        expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      end
    end

    context 'バリデーションエラーの場合' do
      let(:params) do
        {
          schedule: {
            name: '',
            start_date: '2026-01-10',
            end_date: '2026-01-15'
          }
        }
      end

      it 'しおりが作成されないこと' do
        group_without_schedule = create(:group, created_by_user_id: user.id)
        create(:group_membership, group: group_without_schedule, user: user)

        expect {
          post group_schedule_path(group_without_schedule), params: params
        }.to change(Schedule, :count).by(0)
      end
    end

    context 'グループメンバーではない場合' do
      let(:params) do
        {
          schedule: {
            name: 'テストしおり',
            start_date: '2026-01-10',
            end_date: '2026-01-15'
          }
        }
      end

      it 'グループ一覧ページにリダイレクトされること' do
        post group_schedule_path(other_group), params: params
        expect(response).to redirect_to(groups_path)
      end
    end

    context '未ログイン時' do
      before { sign_out user }

      it 'トップページにリダイレクトされること' do
        post group_schedule_path(group), params: { schedule: { name: 'test' } }
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'GET /groups/:group_id/schedule' do
    it 'しおり詳細ページが表示されること' do
      get group_schedule_path(group)
      expect(response).to have_http_status(:success)
    end

    context 'グループメンバーではない場合' do
      it 'グループ一覧ページにリダイレクトされること' do
        get group_schedule_path(other_group)
        expect(response).to redirect_to(groups_path)
      end
    end

    context '未ログイン時' do
      before { sign_out user }

      it 'トップページにリダイレクトされること' do
        get group_schedule_path(group)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'GET /groups/:group_id/schedule/edit' do
    it 'しおり編集フォームが表示されること' do
      get edit_group_schedule_path(group)
      expect(response).to have_http_status(:success)
    end

    context 'グループメンバーではない場合' do
      it 'グループ一覧ページにリダイレクトされること' do
        get edit_group_schedule_path(other_group)
        expect(response).to redirect_to(groups_path)
      end
    end

    context '未ログイン時' do
      before { sign_out user }

      it 'トップページにリダイレクトされること' do
        get edit_group_schedule_path(group)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'PATCH /groups/:group_id/schedule' do
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
      patch group_schedule_path(group), params: params
      group_schedule.reload
      expect(group_schedule.name).to eq('更新後のしおり名')
    end

    it 'グループ詳細ページにリダイレクトされること' do
      patch group_schedule_path(group), params: params
      expect(response).to redirect_to(group_schedule_path(group))
    end

    it '成功メッセージが表示されること' do
      patch group_schedule_path(group), params: params
      follow_redirect!
      expect(response.body).to include('しおりを更新しました')
    end

    context 'バリデーションエラーの場合' do
      let(:invalid_params) do
        {
          schedule: {
            name: '',
            start_date: '2026-01-10',
            end_date: '2026-01-15'
          }
        }
      end

      it 'しおりが更新されないこと' do
        original_name = group_schedule.name
        patch group_schedule_path(group), params: invalid_params
        group_schedule.reload
        expect(group_schedule.name).to eq(original_name)
      end
    end

    context 'グループメンバーではない場合' do
      it 'グループ一覧ページにリダイレクトされること' do
        patch group_schedule_path(other_group), params: params
        expect(response).to redirect_to(groups_path)
      end
    end

    context '未ログイン時' do
      before { sign_out user }

      it 'トップページにリダイレクトされること' do
        patch group_schedule_path(group), params: params
        expect(response).to redirect_to(root_path)
      end
    end
  end

end
