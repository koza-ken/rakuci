require 'rails_helper'

RSpec.describe 'Groups::Spots', type: :request do
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
  let(:category) { create(:category) }
  let(:card) { create(:card, :for_group, cardable: group) }
  let(:spot) { create(:spot, card: card, category: category) }

  before { sign_in user }

  describe 'POST /groups/:group_id/cards/:card_id/spots' do
    context 'スポットを1件作成する場合' do
      let(:params) do
        {
          spot: {
            name: 'テストスポット',
            address: '東京都渋谷区',
            phone_number: '03-1234-5678',
            website_url: 'https://example.com',
            category_id: category.id
          }
        }
      end

      it 'スポットが1件作成されること' do
        expect {
          post group_card_spots_path(group, card), params: params
        }.to change(Spot, :count).by(1)
      end

      it 'グループカード詳細ページにリダイレクトされること' do
        post group_card_spots_path(group, card), params: params
        expect(response).to redirect_to(group_card_path(group, card))
      end

      it '成功メッセージが表示されること' do
        post group_card_spots_path(group, card), params: params
        follow_redirect!
        expect(response.body).to include('スポットを追加しました')
      end

      it 'turbo_streamのレスポンスが返ること' do
        post group_card_spots_path(group, card), params: params, as: :turbo_stream
        expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      end
    end

    context 'バリデーションエラーの場合' do
      let(:invalid_params) do
        {
          spot: {
            name: '',
            address: '東京都渋谷区',
            category_id: category.id
          }
        }
      end

      it 'スポットが作成されないこと' do
        expect {
          post group_card_spots_path(group, card), params: invalid_params
        }.not_to change(Spot, :count)
      end
    end

    context 'グループメンバーではない場合' do
      let(:other_card) { create(:card, :for_group, cardable: other_group) }
      let(:params) do
        {
          spot: {
            name: 'テストスポット',
            category_id: category.id
          }
        }
      end

      it 'グループ一覧ページにリダイレクトされること' do
        post group_card_spots_path(other_group, other_card), params: params
        expect(response).to redirect_to(groups_path)
      end
    end

    context '未ログイン時' do
      before { sign_out user }

      it 'トップページにリダイレクトされること' do
        post group_card_spots_path(group, card), params: { spot: { name: 'test', category_id: category.id } }
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'GET /group/spots/:id' do
    it 'スポット詳細ページが表示されること' do
      get group_spot_path(spot)
      expect(response).to have_http_status(:success)
    end

    context 'グループメンバーではない場合' do
      let(:other_card) { create(:card, :for_group, cardable: other_group) }
      let(:other_spot) { create(:spot, card: other_card, category: category) }

      it 'グループ一覧ページにリダイレクトされること' do
        get group_spot_path(other_spot)
        expect(response).to redirect_to(groups_path)
      end
    end

    context '未ログイン時' do
      before { sign_out user }

      it 'トップページにリダイレクトされること' do
        get group_spot_path(spot)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'GET /group/spots/:id/edit' do
    it 'スポット編集フォームが表示されること' do
      get edit_group_spot_path(spot)
      expect(response).to have_http_status(:success)
    end

    context 'グループメンバーではない場合' do
      let(:other_card) { create(:card, :for_group, cardable: other_group) }
      let(:other_spot) { create(:spot, card: other_card, category: category) }

      it 'グループ一覧ページにリダイレクトされること' do
        get edit_group_spot_path(other_spot)
        expect(response).to redirect_to(groups_path)
      end
    end

    context '未ログイン時' do
      before { sign_out user }

      it 'トップページにリダイレクトされること' do
        get edit_group_spot_path(spot)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'PATCH /group/spots/:id' do
    let(:params) do
      {
        spot: {
          name: '更新後のスポット名',
          address: '大阪府大阪市',
          category_id: category.id
        }
      }
    end

    it 'スポットが更新されること' do
      patch group_spot_path(spot), params: params
      spot.reload
      expect(spot.name).to eq('更新後のスポット名')
      expect(spot.address).to eq('大阪府大阪市')
    end

    it 'スポット詳細ページにリダイレクトされること' do
      patch group_spot_path(spot), params: params
      expect(response).to redirect_to(group_spot_path(spot))
    end

    it '成功メッセージが表示されること' do
      patch group_spot_path(spot), params: params
      follow_redirect!
      expect(response.body).to include('スポットを更新しました')
    end

    context 'バリデーションエラーの場合' do
      let(:invalid_params) do
        {
          spot: {
            name: '',
            category_id: category.id
          }
        }
      end

      it 'スポットが更新されないこと' do
        original_name = spot.name
        patch group_spot_path(spot), params: invalid_params
        spot.reload
        expect(spot.name).to eq(original_name)
      end
    end

    context 'グループメンバーではない場合' do
      let(:other_card) { create(:card, :for_group, cardable: other_group) }
      let(:other_spot) { create(:spot, card: other_card, category: category) }

      it 'グループ一覧ページにリダイレクトされること' do
        patch group_spot_path(other_spot), params: params
        expect(response).to redirect_to(groups_path)
      end
    end

    context '未ログイン時' do
      before { sign_out user }

      it 'トップページにリダイレクトされること' do
        patch group_spot_path(spot), params: params
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'DELETE /group/spots/:id' do
    it 'スポットが削除されること' do
      spot_id = spot.id
      expect {
        delete group_spot_path(spot)
      }.to change(Spot, :count).by(-1)
    end

    it 'グループカード詳細ページにリダイレクトされること' do
      delete group_spot_path(spot)
      expect(response).to redirect_to(group_card_path(group, card))
    end

    it '削除メッセージが表示されること' do
      delete group_spot_path(spot)
      follow_redirect!
      expect(response.body).to include('スポットを削除しました')
    end

    context 'グループメンバーではない場合' do
      let(:other_card) { create(:card, :for_group, cardable: other_group) }
      let(:other_spot) { create(:spot, card: other_card, category: category) }

      it 'グループ一覧ページにリダイレクトされること' do
        delete group_spot_path(other_spot)
        expect(response).to redirect_to(groups_path)
      end
    end

    context '未ログイン時' do
      before { sign_out user }

      it 'トップページにリダイレクトされること' do
        delete group_spot_path(spot)
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
