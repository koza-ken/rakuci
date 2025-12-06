require "rails_helper"

RSpec.describe "権限チェック", type: :request do
  let(:user_a) { create(:user) }
  let(:user_b) { create(:user) }
  let(:category) { create(:category) }

  describe "個人カードへのアクセス制限" do
    it "他のユーザーは別のユーザーの個人カードを閲覧できない" do
      card = create(:card, user: user_a)

      sign_in user_b

      get "/cards/#{card.id}"
      expect(response).to redirect_to(/\/cards/)
    end
  end

  describe "グループカードへのアクセス制限" do
    it "グループメンバーではないユーザーはグループカードを閲覧できない" do
      group = create(:group, creator: user_a)
      card = create(:card, :for_group, group: group)

      sign_in user_b

      get "/cards/#{card.id}"
      expect(response).to redirect_to(/\/cards/)
    end
  end

  describe "カード削除権限チェック" do
    it "カードの所有者でないユーザーはカードを削除できない" do
      card = create(:card, user: user_a)

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
      card = create(:card, :for_group, group: group)

      # user_b がいいねを作成
      create(:like, card: card, group_membership: membership_b)

      # user_a がログイン
      sign_in user_a

      # user_a は user_b のいいねを削除しようとする（削除権限なし）
      delete "/cards/#{card.id}/likes"
      expect(response).to redirect_to(/\/cards/)

      # いいねが削除されていないことを確認
      expect(card.likes.count).to eq(1)
    end
  end
end
