require "rails_helper"

RSpec.describe "権限チェック", type: :request do
  let(:user_a) { create(:user) }
  let(:user_b) { create(:user) }
  let(:category) { create(:category) }

  describe "個人カードへのアクセス制限" do
    it "他のユーザーは別のユーザーの個人カードを閲覧できない" do
      card = create(:card, :for_user, cardable: user_a)

      sign_in user_b

      get "/cards/#{card.id}"
      expect(response).to redirect_to(/\/cards/)
    end
  end

  describe "グループカードへのアクセス制限" do
    it "グループメンバーではないユーザーはグループカードを閲覧できない" do
      group = create(:group, creator: user_a)
      card = create(:card, :for_group, cardable: group)

      sign_in user_b

      get "/cards/#{card.id}"
      expect(response).to redirect_to(/\/cards/)
    end
  end

  describe "カード削除権限チェック" do
    it "カードの所有者でないユーザーはカードを削除できない" do
      card = create(:card, :for_user, cardable: user_a)

      sign_in user_b

      delete "/cards/#{card.id}"
      expect(response).to redirect_to(/\/cards/)

      expect(Card.find_by(id: card.id)).not_to be_nil
    end
  end

  describe "いいね削除権限チェック" do
    it "いいねの所有者でないユーザーはいいねを削除できない" do
      group = create(:group, creator: user_a)
      membership_a = create(:group_membership, user: user_a, group: group, group_nickname: "Aのニックネーム")
      membership_b = create(:group_membership, user: user_b, group: group, group_nickname: "Bのニックネーム")
      card = create(:card, :for_group, cardable: group)

      # user_b がいいねを作成
      create(:like, card: card, group_membership: membership_b)

      # user_a がログイン
      sign_in user_a

      # user_a は user_b のいいねを削除しようとする（削除権限なし）
      delete "/groups/#{group.id}/cards/#{card.id}/likes"
      expect(response).to redirect_to(/\/groups/)

      # いいねが削除されていないことを確認
      expect(card.likes.count).to eq(1)
    end
  end

  describe "個人カードスポットへのアクセス制限" do
    it "他のユーザーは別のユーザーの個人カードのスポットを閲覧できない" do
      card = create(:card, :for_user, cardable: user_a)
      spot = create(:spot, card: card)

      sign_in user_b

      get "/user/spots/#{spot.id}"
      expect(response).to redirect_to(/\/cards/)
    end

    it "他のユーザーは別のユーザーの個人カードのスポットを削除できない" do
      card = create(:card, :for_user, cardable: user_a)
      spot = create(:spot, card: card)

      sign_in user_b

      delete "/user/spots/#{spot.id}"
      expect(response).to redirect_to(/\/cards/)

      expect(Spot.find_by(id: spot.id)).not_to be_nil
    end
  end

  describe "グループカードスポットへのアクセス制限" do
    it "グループメンバーではないユーザーはグループカードのスポットを閲覧できない" do
      group = create(:group, creator: user_a)
      card = create(:card, :for_group, cardable: group)
      spot = create(:spot, card: card)

      sign_in user_b

      get "/group/spots/#{spot.id}"
      expect(response).to redirect_to(/\/groups/)
    end

    it "グループメンバーではないユーザーはグループカードのスポットを削除できない" do
      group = create(:group, creator: user_a)
      card = create(:card, :for_group, cardable: group)
      spot = create(:spot, card: card)

      sign_in user_b

      delete "/group/spots/#{spot.id}"
      expect(response).to redirect_to(/\/groups/)

      expect(Spot.find_by(id: spot.id)).not_to be_nil
    end
  end

  describe "グループカードコメント削除権限チェック" do
    it "コメント作成者でないユーザーはコメントを削除できない" do
      group = create(:group, creator: user_a)
      membership_a = create(:group_membership, user: user_a, group: group, group_nickname: "Aのニックネーム")
      membership_b = create(:group_membership, user: user_b, group: group, group_nickname: "Bのニックネーム")
      card = create(:card, :for_group, cardable: group)

      # user_b がコメントを作成
      comment = create(:comment, card: card, group_membership: membership_b)

      # user_a がログイン
      sign_in user_a

      # user_a は user_b のコメントを削除しようとする（削除権限なし）
      delete "/groups/#{group.id}/cards/#{card.id}/comments/#{comment.id}"
      expect(response).to redirect_to(/\/groups/)

      # コメントが削除されていないことを確認
      expect(Comment.find_by(id: comment.id)).not_to be_nil
    end
  end

  describe "グループカードへのゲストアクセス制限" do
    it "グループに参加していないユーザーはグループカードを閲覧できない" do
      group = create(:group, creator: user_a)
      card = create(:card, :for_group, cardable: group)

      # user_b はグループに参加していない
      sign_in user_b

      get "/groups/#{group.id}/cards/#{card.id}"
      expect(response).to redirect_to(/\/groups/)
    end

    it "グループに参加していないユーザーはグループカードのスポットを作成できない" do
      group = create(:group, creator: user_a)
      card = create(:card, :for_group, cardable: group)
      category = create(:category)

      sign_in user_b

      post "/groups/#{group.id}/cards/#{card.id}/spots", params: {
        spot: {
          name: "テストスポット",
          category_id: category.id
        }
      }
      expect(response).to redirect_to(/\/groups/)
    end
  end
end
