require 'rails_helper'

RSpec.describe 'Groups::ScheduleSpots', type: :request do
  let(:user) { create(:user) }
  let(:group) do
    group = create(:group, created_by_user_id: user.id)
    create(:group_membership, group: group, user: user)
    create(:schedule, schedulable: group)
    group
  end
  let(:card) { create(:card, cardable: group) }
  let(:schedule) { group.schedule }
  let!(:spot1) { create(:spot, card: card) }
  let!(:spot2) { create(:spot, card: card) }

  before { sign_in user }

  describe 'POST /groups/:group_id/cards/:card_id/schedule_spots' do
    context 'グループカードの1個のスポットをしおりに追加する場合' do
      let(:params) do
        {
          spot_id: spot1.id,
          card_id: card.id
        }
      end

      it 'グループしおりにスポットが1件追加されること' do
        expect {
          post group_card_schedule_spots_path(group, card), params: params
        }.to change(ScheduleSpot, :count).by(1)
      end
    end

    context 'グループカードの複数スポットをしおりに追加する場合' do
      let(:params) do
        {
          spot_ids: [spot1.id, spot2.id],
          card_id: card.id
        }
      end

      it 'しおりにスポットが2件追加されること' do
        expect {
          post group_card_schedule_spots_path(group, card), params: params
        }.to change(ScheduleSpot, :count).by(2)
      end

      it 'turbo_streamのレスポンスが返ること' do
        post group_card_schedule_spots_path(group, card), params: params, as: :turbo_stream
        expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      end
    end

  end

  describe 'GET /group/schedule_spots/:id/edit' do
    let(:schedule_spot) { create(:schedule_spot, schedule: schedule) }

    it 'グループしおりのスポット編集フォームが表示されること' do
      get edit_group_schedule_spot_path(schedule_spot)
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /group/schedule_spots/:id' do
    let(:schedule_spot) { create(:schedule_spot, schedule: schedule) }

    it 'しおりのスポットが正常に表示されること' do
      get group_schedule_spot_path(schedule_spot)
      expect(response).to have_http_status(:success)
    end
  end

  describe 'PATCH /group/schedule_spots/:id' do
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
      patch group_schedule_spot_path(schedule_spot), params: params
      schedule_spot.reload
      expect(schedule_spot.snapshot_name).to eq('更新後の名前')
      expect(schedule_spot.memo).to eq('更新後のメモ')
    end

    it 'スポット詳細ページにリダイレクトされること' do
      patch group_schedule_spot_path(schedule_spot), params: params
      expect(response).to redirect_to(group_schedule_spot_path(schedule_spot))
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
        patch group_schedule_spot_path(schedule_spot), params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'ScheduleSpotが更新されないこと' do
        original_name = schedule_spot.snapshot_name
        patch group_schedule_spot_path(schedule_spot), params: invalid_params
        schedule_spot.reload
        expect(schedule_spot.snapshot_name).to eq(original_name)
      end
    end
  end

  describe 'DELETE /group/schedule_spots/:id' do
    let!(:schedule_spot) { create(:schedule_spot, schedule: schedule) }

    it 'しおりのスポットが削除されること' do
      expect {
        delete group_schedule_spot_path(schedule_spot)
      }.to change(ScheduleSpot, :count).by(-1)
    end

    it 'グループスケジュールページにリダイレクトされること' do
      delete group_schedule_spot_path(schedule_spot)
      expect(response).to redirect_to(group_schedule_path(group))
    end
  end

end
