require 'rails_helper'

RSpec.describe 'Groups::Cards', type: :request do
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
  let(:card) { create(:card, :for_group, cardable: group) }

  before { sign_in user }

  describe 'POST /groups/:group_id/cards' do
    context 'グループカードを1件作成する場合' do
      let(:params) do
        {
          card: {
            name: 'テスト グループカード',
            memo: 'テスト用のメモです'
          }
        }
      end

      it 'カードが1件作成されること' do
        expect {
          post group_cards_path(group), params: params
        }.to change(Card, :count).by(1)
      end

      it 'グループ詳細ページにリダイレクトされること' do
        post group_cards_path(group), params: params
        expect(response).to redirect_to(group_path(group))
      end

      it '成功メッセージが表示されること' do
        post group_cards_path(group), params: params
        follow_redirect!
        expect(response.body).to include('カードが作成されました')
      end

      it 'turbo_streamのレスポンスが返ること' do
        post group_cards_path(group), params: params, as: :turbo_stream
        expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      end
    end

    context 'バリデーションエラーの場合' do
      let(:invalid_params) do
        {
          card: {
            name: '',  # 空文字列は無効
            memo: 'テスト用のメモです'
          }
        }
      end

      it 'カードが作成されないこと' do
        expect {
          post group_cards_path(group), params: invalid_params
        }.to change(Card, :count).by(0)
      end

      it '新規作成フォームが再表示されること' do
        post group_cards_path(group), params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'グループメンバーではない場合' do
      let(:params) do
        {
          card: {
            name: 'テストカード',
            memo: 'メモ'
          }
        }
      end

      it 'グループ一覧ページにリダイレクトされること' do
        post group_cards_path(other_group), params: params
        expect(response).to redirect_to(groups_path)
      end

      it 'カードが作成されないこと' do
        expect {
          post group_cards_path(other_group), params: params
        }.to change(Card, :count).by(0)
      end
    end

    context '未ログイン時' do
      before { sign_out user }

      it 'トップページにリダイレクトされること' do
        post group_cards_path(group), params: { card: { name: 'test' } }
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'GET /groups/:group_id/cards/:id' do
    it 'カード詳細ページが表示されること' do
      get group_card_path(group, card)
      expect(response).to have_http_status(:success)
    end

    context '別のグループのカードにアクセスする場合' do
      let(:other_card) { create(:card, :for_group, cardable: other_group) }

      it 'グループ詳細ページにリダイレクトされること' do
        get group_card_path(group, other_card)
        expect(response).to redirect_to(group_path(group))
      end
    end

    context 'グループメンバーではない場合' do
      let(:other_card) { create(:card, :for_group, cardable: other_group) }

      it 'グループ一覧ページにリダイレクトされること' do
        get group_card_path(other_group, other_card)
        expect(response).to redirect_to(groups_path)
      end
    end

    context '未ログイン時' do
      before { sign_out user }

      it 'トップページにリダイレクトされること' do
        get group_card_path(group, card)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'PATCH /groups/:group_id/cards/:id' do
    let(:params) do
      {
        card: {
          name: '更新後のカード名',
          memo: '更新後のメモ'
        }
      }
    end

    it 'カードが更新されること' do
      patch group_card_path(group, card), params: params
      card.reload
      expect(card.name).to eq('更新後のカード名')
      expect(card.memo).to eq('更新後のメモ')
    end

    it 'カード詳細ページにリダイレクトされること' do
      patch group_card_path(group, card), params: params
      expect(response).to redirect_to(group_card_path(group, card))
    end

    it '成功メッセージが表示されること' do
      patch group_card_path(group, card), params: params
      follow_redirect!
      expect(response.body).to include('カードが更新されました')
    end

    it 'turbo_streamのレスポンスが返ること' do
      patch group_card_path(group, card), params: params, as: :turbo_stream
      expect(response.media_type).to eq('text/vnd.turbo-stream.html')
    end

    context 'バリデーションエラーの場合' do
      let(:invalid_params) do
        {
          card: {
            name: '',  # 空文字列は無効
            memo: 'メモ'
          }
        }
      end

      it 'カードが更新されないこと' do
        original_name = card.name
        patch group_card_path(group, card), params: invalid_params, as: :turbo_stream
        card.reload
        expect(card.name).to eq(original_name)
      end

      it 'turbo_streamのレスポンスが返ること' do
        patch group_card_path(group, card), params: invalid_params, as: :turbo_stream
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      end
    end

    context 'グループメンバーではない場合' do
      let(:other_card) { create(:card, :for_group, cardable: other_group) }

      it 'グループ一覧ページにリダイレクトされること' do
        patch group_card_path(other_group, other_card), params: params
        expect(response).to redirect_to(groups_path)
      end
    end

    context '未ログイン時' do
      before { sign_out user }

      it 'トップページにリダイレクトされること' do
        patch group_card_path(group, card), params: params
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'DELETE /groups/:group_id/cards/:id' do
    it 'カードが削除されること' do
      card_id = card.id
      expect {
        delete group_card_path(group, card)
      }.to change(Card, :count).by(-1)
    end

    it 'グループ詳細ページにリダイレクトされること' do
      delete group_card_path(group, card)
      expect(response).to redirect_to(group_path(group))
    end

    it '削除メッセージが表示されること' do
      delete group_card_path(group, card)
      follow_redirect!
      expect(response.body).to include('カードが削除されました')
    end

    context 'グループメンバーではない場合' do
      let(:other_card) { create(:card, :for_group, cardable: other_group) }

      it 'グループ一覧ページにリダイレクトされること' do
        delete group_card_path(other_group, other_card)
        expect(response).to redirect_to(groups_path)
      end
    end

    context '未ログイン時' do
      before { sign_out user }

      it 'トップページにリダイレクトされること' do
        delete group_card_path(group, card)
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
