require 'rails_helper'

RSpec.describe 'Users::ScheduleSpots', type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:card) { create(:card, cardable: user) }
  let(:schedule) { create(:schedule, schedulable: user) }
  let!(:spot1) { create(:spot, card: card) }
  let!(:spot2) { create(:spot, card: card) }

  before { sign_in user }

  describe 'POST /cards/:card_id/schedule_spots' do
    context '個人カードの1個のスポットをしおりに追加する場合' do
      let(:params) do
        {
          spot_id: spot1.id,
          schedule_id: schedule.id
        }
      end

      it '個人しおりにスポットが1件追加されること' do
        expect {
          post card_schedule_spots_path(card), params: params
        }.to change(ScheduleSpot, :count).by(1)
      end

      it '個人しおりにスポットが追加されると、カード詳細ページにリダイレクトされること' do
        post card_schedule_spots_path(card), params: params
        expect(response).to redirect_to(card_path(card))
      end
    end

    context '個人カードの複数スポットをしおりに追加する場合' do
      let(:params) do
        {
          spot_ids: [ spot1.id, spot2.id ],
          schedule_id: schedule.id
        }
      end

      it '個人しおりにスポットが2件追加されること' do
        expect {
          post card_schedule_spots_path(card), params: params
        }.to change(ScheduleSpot, :count).by(2)
      end

      it '個人しおりにスポットが追加されると、カード詳細ページにリダイレクトされること' do
        post card_schedule_spots_path(card), params: params
        expect(response).to redirect_to(card_path(card))
      end

      it '成功メッセージが表示されること' do
        post card_schedule_spots_path(card), params: params
        follow_redirect!
        expect(response.body).to include('2件のスポットを追加しました')
      end
    end

    context '未ログイン時' do
      before { sign_out user }

      it 'ログインページにリダイレクトされること' do
        post card_schedule_spots_path(card), params: { spot_ids: [ spot1.id ], schedule_id: schedule.id }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context '他人のカードにアクセスする場合' do
      let(:other_user) { create(:user) }
      let(:other_card) { create(:card, cardable: other_user) }

      it 'current_user.cards.findが失敗して404が返ること' do
        post card_schedule_spots_path(other_card), params: { spot_ids: [ spot1.id ], schedule_id: schedule.id }
        expect(response).to have_http_status(404)
      end
    end
  end

  describe 'GET /schedule_spots/:id' do
    let(:schedule_spot) { create(:schedule_spot, schedule: schedule) }

    it 'しおりのスポットが正常に表示されること' do
      get user_schedule_spot_path(schedule_spot)
      expect(response).to have_http_status(:success)
    end

    context '未ログイン時' do
      before { sign_out user }

      it 'ログインページにリダイレクトされること' do
        get user_schedule_spot_path(schedule_spot)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /schedule_spots/:id/edit' do
    let(:schedule_spot) { create(:schedule_spot, schedule: schedule) }

    it 'スポット編集フォームが表示されること' do
      get edit_user_schedule_spot_path(schedule_spot)
      expect(response).to have_http_status(:success)
      expect(response.body).to include('編集')
    end
  end

  describe 'PATCH /schedule_spots/:id' do
    let(:schedule_spot) { create(:schedule_spot, schedule: schedule, snapshot_name: '元の名前') }
    let(:params) do
      {
        schedule_spot: {
          snapshot_name: '更新後の名前',
          memo: '更新後のメモ'
        }
      }
    end

    it 'しおりのスポットが更新されること' do
      patch user_schedule_spot_path(schedule_spot), params: params
      schedule_spot.reload
      expect(schedule_spot.snapshot_name).to eq('更新後の名前')
      expect(schedule_spot.memo).to eq('更新後のメモ')
    end

    it 'スポット詳細ページにリダイレクトされること' do
      patch user_schedule_spot_path(schedule_spot), params: params
      expect(response).to redirect_to(user_schedule_spot_path(schedule_spot))
    end

    context 'バリデーションエラーの場合' do
      let(:invalid_params) do
        {
          schedule_spot: {
            snapshot_name: '',  # 空文字列は無効
            day_number: 0       # 0は無効
          }
        }
      end

      it '編集フォームが再表示されること' do
        patch user_schedule_spot_path(schedule_spot), params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include('編集')
      end

      it 'ScheduleSpotが更新されないこと' do
        original_name = schedule_spot.snapshot_name
        patch user_schedule_spot_path(schedule_spot), params: invalid_params
        schedule_spot.reload
        expect(schedule_spot.snapshot_name).to eq(original_name)
      end
    end

    context '未ログイン時' do
      before { sign_out user }

      it 'ログインページにリダイレクトされること' do
        patch user_schedule_spot_path(schedule_spot), params: params
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'DELETE /schedule_spots/:id' do
    let!(:schedule_spot) { create(:schedule_spot, schedule: schedule) }

    it 'しおりのスポットが削除されること' do
      expect {
        delete user_schedule_spot_path(schedule_spot)
      }.to change(ScheduleSpot, :count).by(-1)
    end

    it 'しおり詳細ページにリダイレクトされること' do
      delete user_schedule_spot_path(schedule_spot)
      expect(response).to redirect_to(schedule_path(schedule))
    end

    context '未ログイン時' do
      before { sign_out user }

      it 'ログインページにリダイレクトされること' do
        delete user_schedule_spot_path(schedule_spot)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'PATCH /schedule_spots/:id/move_higher' do
    let!(:spot1) { create(:schedule_spot, schedule: schedule, day_number: 1) }
    let!(:spot2) { create(:schedule_spot, schedule: schedule, day_number: 1) }
    let!(:spot3) { create(:schedule_spot, schedule: schedule, day_number: 1) }

    it 'スポットが上に移動すること' do
      patch move_higher_user_schedule_spot_path(spot2), as: :turbo_stream
      expect(spot1.reload.global_position).to eq(2)
      expect(spot2.reload.global_position).to eq(1)
      expect(spot3.reload.global_position).to eq(3)
    end

    it 'Turbo Streamレスポンスが返ること' do
      patch move_higher_user_schedule_spot_path(spot2), as: :turbo_stream
      expect(response.media_type).to eq('text/vnd.turbo-stream.html')
    end

    context '未ログイン時' do
      before { sign_out user }

      it 'ログインページにリダイレクトされること' do
        patch move_higher_user_schedule_spot_path(spot2), as: :turbo_stream
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'PATCH /schedule_spots/:id/move_lower' do
    let!(:spot1) { create(:schedule_spot, schedule: schedule, day_number: 1) }
    let!(:spot2) { create(:schedule_spot, schedule: schedule, day_number: 1) }
    let!(:spot3) { create(:schedule_spot, schedule: schedule, day_number: 1) }

    it 'スポットが下に移動すること' do
      patch move_lower_user_schedule_spot_path(spot2), as: :turbo_stream
      expect(spot1.reload.global_position).to eq(1)
      expect(spot2.reload.global_position).to eq(3)
      expect(spot3.reload.global_position).to eq(2)
    end

    it 'Turbo Streamレスポンスが返ること' do
      patch move_lower_user_schedule_spot_path(spot2), as: :turbo_stream
      expect(response.media_type).to eq('text/vnd.turbo-stream.html')
    end

    context '未ログイン時' do
      before { sign_out user }

      it 'ログインページにリダイレクトされること' do
        patch move_lower_user_schedule_spot_path(spot2), as: :turbo_stream
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
