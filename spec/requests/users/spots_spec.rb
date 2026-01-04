require 'rails_helper'

RSpec.describe 'Users::Spots', type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:card) { create(:card, :for_user, cardable: user) }
  let(:category) { create(:category) }
  let(:spot) { create(:spot, card: card, category: category) }

  before { sign_in user }

  describe 'POST /cards/:card_id/spots' do
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
          post card_spots_path(card), params: params
        }.to change(Spot, :count).by(1)
      end

      it 'カード詳細ページにリダイレクトされること' do
        post card_spots_path(card), params: params
        expect(response).to redirect_to(card_path(card))
      end

      it '成功メッセージが表示されること' do
        post card_spots_path(card), params: params
        follow_redirect!
        expect(response.body).to include('スポットを追加しました')
      end

      it 'turbo_streamのレスポンスが返ること' do
        post card_spots_path(card), params: params, as: :turbo_stream
        expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      end
    end

    context 'バリデーションエラーの場合' do
      let(:invalid_params) do
        {
          spot: {
            name: '',  # 空文字列は無効
            address: '東京都渋谷区',
            category_id: category.id
          }
        }
      end

      it 'スポットが作成されないこと' do
        expect {
          post card_spots_path(card), params: invalid_params
        }.not_to change(Spot, :count)
      end

      it '新規作成フォームが再表示されること' do
        post card_spots_path(card), params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context '他人のカードにスポットを追加する場合' do
      let(:other_card) { create(:card, :for_user, cardable: other_user) }
      let(:params) do
        {
          spot: {
            name: 'テストスポット',
            category_id: category.id
          }
        }
      end

      it 'カード一覧ページにリダイレクトされること' do
        post card_spots_path(other_card), params: params
        expect(response).to redirect_to(cards_path)
      end

      it 'スポットが作成されないこと' do
        expect {
          post card_spots_path(other_card), params: params
        }.not_to change(Spot, :count)
      end
    end

    context '未ログイン時' do
      before { sign_out user }

      it 'ログインページにリダイレクトされること' do
        post card_spots_path(card), params: { spot: { name: 'test', category_id: category.id } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /spots/:id' do
    it 'スポット詳細ページが表示されること' do
      get user_spot_path(spot)
      expect(response).to have_http_status(:success)
    end

    context '他人のカードのスポットにアクセスする場合' do
      let(:other_card) { create(:card, :for_user, cardable: other_user) }
      let(:other_spot) { create(:spot, card: other_card, category: category) }

      it 'カード一覧ページにリダイレクトされること' do
        get user_spot_path(other_spot)
        expect(response).to redirect_to(cards_path)
      end
    end

    context '未ログイン時' do
      before { sign_out user }

      it 'ログインページにリダイレクトされること' do
        get user_spot_path(spot)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /spots/:id/edit' do
    it 'スポット編集フォームが表示されること' do
      get edit_user_spot_path(spot)
      expect(response).to have_http_status(:success)
    end

    context '他人のカードのスポットを編集する場合' do
      let(:other_card) { create(:card, :for_user, cardable: other_user) }
      let(:other_spot) { create(:spot, card: other_card, category: category) }

      it 'カード一覧ページにリダイレクトされること' do
        get edit_user_spot_path(other_spot)
        expect(response).to redirect_to(cards_path)
      end
    end

    context '未ログイン時' do
      before { sign_out user }

      it 'ログインページにリダイレクトされること' do
        get edit_user_spot_path(spot)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'PATCH /spots/:id' do
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
      patch user_spot_path(spot), params: params
      spot.reload
      expect(spot.name).to eq('更新後のスポット名')
      expect(spot.address).to eq('大阪府大阪市')
    end

    it 'スポット詳細ページにリダイレクトされること' do
      patch user_spot_path(spot), params: params
      expect(response).to redirect_to(user_spot_path(spot))
    end

    it '成功メッセージが表示されること' do
      patch user_spot_path(spot), params: params
      follow_redirect!
      expect(response.body).to include('スポットを更新しました')
    end

    context 'バリデーションエラーの場合' do
      let(:invalid_params) do
        {
          spot: {
            name: '',  # 空文字列は無効
            category_id: category.id
          }
        }
      end

      it 'スポットが更新されないこと' do
        original_name = spot.name
        patch user_spot_path(spot), params: invalid_params
        spot.reload
        expect(spot.name).to eq(original_name)
      end

      it 'スポット編集フォームが再表示されること' do
        patch user_spot_path(spot), params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context '他人のカードのスポットを更新する場合' do
      let(:other_card) { create(:card, :for_user, cardable: other_user) }
      let(:other_spot) { create(:spot, card: other_card, category: category) }

      it 'カード一覧ページにリダイレクトされること' do
        patch user_spot_path(other_spot), params: params
        expect(response).to redirect_to(cards_path)
      end
    end

    context '未ログイン時' do
      before { sign_out user }

      it 'ログインページにリダイレクトされること' do
        patch user_spot_path(spot), params: params
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'DELETE /spots/:id' do
    it 'スポットが削除されること' do
      spot_id = spot.id
      expect {
        delete user_spot_path(spot)
      }.to change(Spot, :count).by(-1)
    end

    it 'カード詳細ページにリダイレクトされること' do
      delete user_spot_path(spot)
      expect(response).to redirect_to(card_path(card))
    end

    it '削除メッセージが表示されること' do
      delete user_spot_path(spot)
      follow_redirect!
      expect(response.body).to include('スポットを削除しました')
    end

    context '他人のカードのスポットを削除する場合' do
      let(:other_card) { create(:card, :for_user, cardable: other_user) }
      let(:other_spot) { create(:spot, card: other_card, category: category) }

      it 'カード一覧ページにリダイレクトされること' do
        delete user_spot_path(other_spot)
        expect(response).to redirect_to(cards_path)
      end

      it 'エラーメッセージが表示されること' do
        delete user_spot_path(other_spot)
        follow_redirect!
        expect(response.body).to include('このカードを閲覧する権限がありません')
      end
    end

    context '未ログイン時' do
      before { sign_out user }

      it 'ログインページにリダイレクトされること' do
        delete user_spot_path(spot)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
