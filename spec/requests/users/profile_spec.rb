require 'rails_helper'

RSpec.describe "Users::Profile", type: :request do
  describe "GET /profile" do
    context "ログインしていない場合" do
      it "ログインページにリダイレクトされる" do
        get profile_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "通常ユーザーでログインしている場合" do
      let(:user) { create(:user, email: "test@example.com", password: "password123") }

      before do
        sign_in user
      end

      it "プロフィールページが表示される" do
        get profile_path
        expect(response).to have_http_status(:success)
      end

      it "/users/editでもアクセスできる" do
        get edit_user_registration_path
        expect(response).to have_http_status(:success)
      end

      it "現在のパスワードフィールドが表示される" do
        get profile_path
        expect(response.body).to include("現在のパスワード")
      end
    end

    context "Google認証ユーザーでログインしている場合" do
      let(:user) { create(:user, :oauth, email: "google@example.com") }

      before do
        sign_in user
      end

      it "プロフィールページが表示される" do
        get profile_path
        expect(response).to have_http_status(:success)
      end

      it "Googleアカウントでログイン中のバナーが表示される" do
        get profile_path
        expect(response.body).to include("Googleアカウントでログイン中")
      end

      it "メールアドレスが変更不可で表示される" do
        get profile_path
        expect(response.body).to include("Googleアカウントのメールアドレスは変更できません")
      end

      it "パスワードフィールドが表示されない" do
        get profile_path
        expect(response.body).not_to include("現在のパスワード")
      end
    end
  end

  describe "PATCH /users" do
    context "通常ユーザーの場合" do
      let(:user) { create(:user, display_name: "旧名前", email: "test@example.com", password: "password123") }

      before do
        sign_in user
      end

      context "ユーザー名のみ変更する場合" do
        it "current_passwordなしで更新できる" do
          patch user_registration_path, params: {
            user: {
              display_name: "新名前",
              email: user.email
            }
          }
          expect(response).to redirect_to(profile_path)
          user.reload
          expect(user.display_name).to eq("新名前")
        end
      end

      context "メールアドレスを変更する場合" do
        it "current_passwordがないと更新できない" do
          patch user_registration_path, params: {
            user: {
              display_name: user.display_name,
              email: "new@example.com"
            }
          }
          expect(response).to have_http_status(:unprocessable_entity) # 422エラー
          user.reload
          expect(user.email).to eq("test@example.com") # 変更されていない
        end

        it "current_passwordがあると更新できる" do
          patch user_registration_path, params: {
            user: {
              display_name: user.display_name,
              email: "new@example.com",
              current_password: "password123"
            }
          }
          expect(response).to redirect_to(profile_path)
          user.reload
          expect(user.email).to eq("new@example.com")
        end
      end

      context "バリデーションエラーの場合" do
        it "ユーザー名が20文字を超えるとエラーが表示される" do
          patch user_registration_path, params: {
            user: {
              display_name: "あ" * 21,
              email: user.email
            }
          }
          expect(response).to have_http_status(:unprocessable_entity) # 422エラー
          expect(response.body).to include("ユーザー名は20文字以内で入力してください")
        end
      end
    end

    context "Google認証ユーザーの場合" do
      let(:user) { create(:user, :oauth, display_name: "旧名前", email: "google@example.com") }

      before do
        sign_in user
      end

      it "current_passwordなしでユーザー名を更新できる" do
        patch user_registration_path, params: {
          user: {
            display_name: "新名前"
          }
        }
        expect(response).to redirect_to(profile_path)
        user.reload
        expect(user.display_name).to eq("新名前")
      end

      it "更新成功メッセージが表示される" do
        patch user_registration_path, params: {
          user: {
            display_name: "新名前"
          }
        }
        follow_redirect!
        expect(response.body).to include("アカウント情報が正常に更新されました")
      end
    end
  end
end
