require "rails_helper"

RSpec.describe "Groups::GroupMemberships", type: :request do
  let(:creator) { create(:user) }
  let(:group) do
    group = create(:group, creator: creator)
    create(:group_membership, group: group, user: creator, role: "owner", group_nickname: "オーナー")
    group
  end

  describe "GET /groups/join/:invite_token (new)" do
    it "招待ページが表示されること" do
      get new_membership_path(group.invite_token)
      expect(response).to have_http_status(:success)
    end

    context "無効なトークンの場合" do
      it "トップページにリダイレクトされること" do
        get new_membership_path("invalid_token")
        expect(response).to redirect_to(root_path)
      end
    end

    context "既にメンバーのユーザーがアクセスした場合" do
      before { sign_in creator }

      it "グループ詳細ページにリダイレクトされること" do
        get new_membership_path(group.invite_token)
        expect(response).to redirect_to(group_path(group.id))
      end
    end
  end

  describe "POST /groups/join/:invite_token (create)" do
    context "新規メンバーとしてログインユーザーが参加する場合" do
      let(:user) { create(:user) }
      let(:params) do
        {
          group_nickname: "新メンバー",
          membership_source: "new"
        }
      end

      before do
        group # let を事前評価（オーナーの membership も含む）
        sign_in user
      end


      it "メンバーシップが作成されること" do
        expect {
          post create_membership_path(group.invite_token), params: params
        }.to change(GroupMembership, :count).by(1)
      end

      it "user_idが設定されること" do
        post create_membership_path(group.invite_token), params: params
        membership = GroupMembership.last
        expect(membership.user).to eq(user)
        expect(membership.group_nickname).to eq("新メンバー")
      end

      it "グループ詳細ページにリダイレクトされること" do
        post create_membership_path(group.invite_token), params: params
        expect(response).to redirect_to(group_path(group.id))
      end
    end

    context "新規メンバーとしてゲストが参加する場合" do
      before { group } # let を事前評価

      let(:params) do
        {
          group_nickname: "ゲスト太郎",
          membership_source: "new"
        }
      end

      it "メンバーシップが作成されること" do
        expect {
          post create_membership_path(group.invite_token), params: params
        }.to change(GroupMembership, :count).by(1)
      end

      it "guest_token_digestが設定されること" do
        post create_membership_path(group.invite_token), params: params
        membership = GroupMembership.last
        expect(membership.user_id).to be_nil
        expect(membership.guest_token_digest).to be_present
      end

      it "グループ詳細ページにリダイレクトされること" do
        post create_membership_path(group.invite_token), params: params
        expect(response).to redirect_to(group_path(group.id))
      end
    end

    context "既存メンバーとして復帰する場合" do
      before do
        create(:group_membership, :guest, group: group, group_nickname: "復帰ゲスト")
      end

      let(:params) do
        {
          group_nickname: "復帰ゲスト",
          membership_source: "existing"
        }
      end

      it "新しいメンバーシップは作成されないこと（既存を再利用）" do
        expect {
          post create_membership_path(group.invite_token), params: params
        }.not_to change(GroupMembership, :count)
      end

      it "グループ詳細ページにリダイレクトされること" do
        post create_membership_path(group.invite_token), params: params
        expect(response).to redirect_to(group_path(group.id))
      end
    end

    context "存在しないニックネームで既存メンバー参加しようとした場合" do
      let(:params) do
        {
          group_nickname: "存在しないニックネーム",
          membership_source: "existing"
        }
      end

      it "招待ページにリダイレクトされること" do
        post create_membership_path(group.invite_token), params: params
        expect(response).to redirect_to(new_membership_path(group.invite_token))
      end
    end

    context "不正な membership_source の場合" do
      let(:params) do
        {
          group_nickname: "テスト",
          membership_source: "invalid"
        }
      end

      it "招待ページにリダイレクトされること" do
        post create_membership_path(group.invite_token), params: params
        expect(response).to redirect_to(new_membership_path(group.invite_token))
      end
    end

    context "無効なトークンの場合" do
      it "トップページにリダイレクトされること" do
        post create_membership_path("invalid_token"), params: { group_nickname: "test", membership_source: "new" }
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "DELETE /groups/:group_id/group_memberships/:id (destroy)" do
    let(:member) do
      create(:group_membership, group: group, role: "member", group_nickname: "メンバー")
    end

    context "オーナーがメンバーを削除する場合" do
      before { sign_in creator }

      it "メンバーシップが削除されること" do
        member # let を評価
        expect {
          delete group_group_membership_path(group, member)
        }.to change(GroupMembership, :count).by(-1)
      end

      it "グループ詳細ページにリダイレクトされること" do
        delete group_group_membership_path(group, member)
        expect(response).to redirect_to(group_path(group))
      end

      it "turbo_streamのレスポンスが返ること" do
        delete group_group_membership_path(group, member), as: :turbo_stream
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end
    end

    context "オーナー自身を削除しようとした場合" do
      before { sign_in creator }

      let(:owner_membership) do
        group.group_memberships.find_by(user: creator)
      end

      it "削除されないこと" do
        owner_membership # let を事前評価
        expect {
          delete group_group_membership_path(group, owner_membership)
        }.not_to change(GroupMembership, :count)
      end

      it "グループ詳細ページにリダイレクトされること" do
        delete group_group_membership_path(group, owner_membership)
        expect(response).to redirect_to(group_path(group))
      end
    end

    context "オーナーでないユーザーが削除しようとした場合" do
      let(:non_owner) { create(:user) }

      before do
        create(:group_membership, group: group, user: non_owner, group_nickname: "非オーナー")
        sign_in non_owner
      end

      it "グループ詳細ページにリダイレクトされること" do
        delete group_group_membership_path(group, member)
        expect(response).to redirect_to(group_path(group))
      end

      it "メンバーシップが削除されないこと" do
        member # let を評価
        expect {
          delete group_group_membership_path(group, member)
        }.not_to change(GroupMembership, :count)
      end
    end

    context "未ログインの場合" do
      it "ログインページにリダイレクトされること" do
        delete group_group_membership_path(group, member)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
