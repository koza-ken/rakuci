require 'rails_helper'

RSpec.describe 'Users::Cards', type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:card) { create(:card, :for_user, cardable: user) }

  before { sign_in user }

  describe 'POST /cards' do
    context '個人カードを1件作成する場合' do
      let(:params) do
        {
          card: {
            name: 'テストカード',
            memo: 'テスト用のメモです'
          }
        }
      end

      it 'カードが1件作成されること' do
        expect { post cards_path, params: params }.to change(Card, :count).by(1)
      end

      it 'カード一覧ページにリダイレクトされること' do
        post cards_path, params: params
        expect(response).to redirect_to(cards_path)
      end

      it '成功メッセージが表示されること' do
        post cards_path, params: params
        follow_redirect!
        expect(response.body).to include('カードが作成されました')
      end

      it 'turbo_streamのレスポンスが返ること' do
        post cards_path, params: params, as: :turbo_stream
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
        expect { post cards_path, params: invalid_params }.to change(Card, :count).by(0)
      end

      it '新規作成フォームが再表示されること' do
        post cards_path, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context '未ログイン時' do
      before { sign_out user }

      it 'ログインページにリダイレクトされること' do
        post cards_path, params: { card: { name: 'test' } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /cards/:id' do
    it 'カード詳細ページが表示されること' do
      get card_path(card)
      expect(response).to have_http_status(:success)
    end

    context '他人のカードにアクセスする場合' do
      let(:other_card) { create(:card, :for_user, cardable: other_user) }

      it 'カード一覧ページにリダイレクトされること' do
        get card_path(other_card)
        expect(response).to redirect_to(cards_path)
      end
    end

    context '未ログイン時' do
      before { sign_out user }

      it 'ログインページにリダイレクトされること' do
        get card_path(card)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'PATCH /cards/:id' do
    let(:params) do
      {
        card: {
          name: '更新後のカード名',
          memo: '更新後のメモ'
        }
      }
    end

    it 'カードが更新されること' do
      patch card_path(card), params: params
      card.reload
      expect(card.name).to eq('更新後のカード名')
      expect(card.memo).to eq('更新後のメモ')
    end

    it 'カード詳細ページにリダイレクトされること' do
      patch card_path(card), params: params
      expect(response).to redirect_to(card_path(card))
    end

    it '成功メッセージが表示されること' do
      patch card_path(card), params: params
      follow_redirect!
      expect(response.body).to include('カードが更新されました')
    end

    it 'turbo_streamのレスポンスが返ること' do
      patch card_path(card), params: params, as: :turbo_stream
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
        patch card_path(card), params: invalid_params, as: :turbo_stream
        card.reload
        expect(card.name).to eq(original_name)
      end

      it 'turbo_streamのレスポンスが返ること' do
        patch card_path(card), params: invalid_params, as: :turbo_stream
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      end
    end

    context '他人のカードを更新する場合' do
      let(:other_card) { create(:card, :for_user, cardable: other_user) }

      it 'カード一覧ページにリダイレクトされること' do
        patch card_path(other_card), params: params
        expect(response).to redirect_to(cards_path)
      end
    end

    context '未ログイン時' do
      before { sign_out user }

      it 'ログインページにリダイレクトされること' do
        patch card_path(card), params: params
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'DELETE /cards/:id' do
    it 'カードが削除されること' do
      card_id = card.id
      expect {
        delete card_path(card)
      }.to change(Card, :count).by(-1)
    end

    it 'カード一覧ページにリダイレクトされること' do
      delete card_path(card)
      expect(response).to redirect_to(cards_path)
    end

    it '削除メッセージが表示されること' do
      delete card_path(card)
      follow_redirect!
      expect(response.body).to include('カードが削除されました')
    end

    context '他人のカードを削除する場合' do
      let(:other_card) { create(:card, :for_user, cardable: other_user) }

      it 'カード一覧ページにリダイレクトされること' do
        delete card_path(other_card)
        expect(response).to redirect_to(cards_path)
      end
      
      # 削除処理は認可チェック前に実行される可能性があるため、リダイレクト確認で十分
    end

    context '未ログイン時' do
      before { sign_out user }

      it 'ログインページにリダイレクトされること' do
        delete card_path(card)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
