require "rails_helper"

RSpec.describe "Groups", type: :request do
  let(:user) { create(:user) }
  let(:group) do
    group = create(:group, creator: user)
    create(:group_membership, group: group, user: user, role: "owner")
    group
  end
  let(:other_user) { create(:user) }

  describe "GET /groups (index)" do
    before { sign_in user }

    it "参加グループ一覧が表示されること" do
      group # let を評価してグループ作成
      get groups_path
      expect(response).to have_http_status(:success)
    end

    context "未ログインの場合" do
      before { sign_out user }

      it "ログインページにリダイレクトされること" do
        get groups_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET /groups/:id (show)" do
    before { sign_in user }

    it "グループ詳細ページが表示されること" do
      get group_path(group)
      expect(response).to have_http_status(:success)
    end

    context "メンバーでないユーザーの場合" do
      before { sign_in other_user }

      it "グループ一覧にリダイレクトされること" do
        get group_path(group)
        expect(response).to redirect_to(groups_path)
      end
    end

    context "未ログイン（ゲストトークンなし）の場合" do
      before { sign_out user }

      it "トップページにリダイレクトされること" do
        get group_path(group)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "GET /groups/new" do
    before { sign_in user }

    it "グループ作成フォームが表示されること" do
      get new_group_path
      expect(response).to have_http_status(:success)
    end

    context "未ログインの場合" do
      before { sign_out user }

      it "ログインページにリダイレクトされること" do
        get new_group_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "POST /groups (create)" do
    before { sign_in user }

    let(:valid_params) do
      {
        group_create_form: {
          name: "新しいグループ",
          group_nickname: "リーダー"
        }
      }
    end

    context "正常なパラメータの場合" do
      it "グループが1件作成されること" do
        expect {
          post groups_path, params: valid_params
        }.to change(Group, :count).by(1)
      end

      it "作成者のメンバーシップも同時に作成されること" do
        expect {
          post groups_path, params: valid_params
        }.to change(GroupMembership, :count).by(1)
      end

      it "作成者がownerロールで登録されること" do
        post groups_path, params: valid_params
        membership = GroupMembership.last
        expect(membership.user).to eq(user)
        expect(membership).to be_owner
      end

      it "グループ一覧にリダイレクトされること" do
        post groups_path, params: valid_params
        expect(response).to redirect_to(groups_path)
      end

      it "turbo_streamのレスポンスが返ること" do
        post groups_path, params: valid_params, as: :turbo_stream
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end
    end

    context "バリデーションエラーの場合" do
      let(:invalid_params) do
        {
          group_create_form: {
            name: "",
            group_nickname: "リーダー"
          }
        }
      end

      it "グループが作成されないこと" do
        expect {
          post groups_path, params: invalid_params
        }.not_to change(Group, :count)
      end

      it "フォームが再表示されること" do
        post groups_path, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "未ログインの場合" do
      before { sign_out user }

      it "ログインページにリダイレクトされること" do
        post groups_path, params: valid_params
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "PATCH /groups/:id (update)" do
    before { sign_in user }

    let(:update_params) { { group: { name: "更新後のグループ名" } } }

    it "グループ名が更新されること" do
      patch group_path(group), params: update_params
      expect(group.reload.name).to eq("更新後のグループ名")
    end

    it "グループ詳細ページにリダイレクトされること" do
      patch group_path(group), params: update_params
      expect(response).to redirect_to(group_path(group))
    end

    it "turbo_streamのレスポンスが返ること" do
      patch group_path(group), params: update_params, as: :turbo_stream
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    end

    context "バリデーションエラーの場合" do
      let(:invalid_params) { { group: { name: "" } } }

      it "グループ名が更新されないこと" do
        original_name = group.name
        patch group_path(group), params: invalid_params, as: :turbo_stream
        expect(group.reload.name).to eq(original_name)
      end

      it "エラーレスポンスが返ること" do
        patch group_path(group), params: invalid_params, as: :turbo_stream
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "メンバーでないユーザーの場合" do
      before { sign_in other_user }

      it "グループ一覧にリダイレクトされること" do
        patch group_path(group), params: update_params
        expect(response).to redirect_to(groups_path)
      end
    end

    context "未ログインの場合" do
      before { sign_out user }

      it "ログインページにリダイレクトされること" do
        patch group_path(group), params: update_params
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "DELETE /groups/:id (destroy)" do
    before { sign_in user }

    it "グループが削除されること" do
      group # let を評価
      expect {
        delete group_path(group)
      }.to change(Group, :count).by(-1)
    end

    it "グループ一覧にリダイレクトされること" do
      delete group_path(group)
      expect(response).to redirect_to(groups_path)
    end

    context "未ログインの場合" do
      before { sign_out user }

      it "ログインページにリダイレクトされること" do
        delete group_path(group)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
