# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  display_name           :string(20)
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  provider               :string(64)
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  uid                    :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_provider_and_uid      (provider,uid) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#
require "rails_helper"

RSpec.describe User, type: :model do
  describe "バリデーション" do
    describe "display_name" do
      context "20文字以下の場合" do
        it "保存に成功する" do
          user = build(:user, display_name: "a" * 20)
          expect(user).to be_valid
        end
      end

      context "21文字以上の場合" do
        it "保存に失敗する" do
          user = build(:user, display_name: "a" * 21)
          expect(user).not_to be_valid
        end
      end

      context "nilの場合" do
        it "保存に成功する" do
          user = build(:user, display_name: nil)
          expect(user).to be_valid
        end
      end
    end

    describe "provider と uid の相互依存" do
      context "両方存在する場合" do
        it "保存に成功する" do
          user = build(:user, :oauth)
          expect(user).to be_valid
        end

        describe "provider の文字数" do
          context "64文字以下の場合" do
            it "保存に成功する" do
              user = build(:user, :oauth, provider: "a" * 64)
              expect(user).to be_valid
            end
          end

          context "65文字以上の場合" do
            it "保存に失敗する" do
              user = build(:user, :oauth, provider: "a" * 65)
              expect(user).not_to be_valid
            end
          end
        end
      end

      context "providerだけ存在する場合" do
        it "保存に失敗する" do
          user = build(:user, :oauth, uid: nil)
          expect(user).not_to be_valid
        end
      end

      context "uidだけ存在する場合" do
        it "保存に失敗する" do
          user = build(:user, :oauth, provider: nil)
          expect(user).not_to be_valid
        end
      end

      context "両方存在しない場合" do
        it "保存に成功する" do
          user = build(:user)
          expect(user).to be_valid
        end
      end
    end
  end

  describe "#oauth_user?" do
    context "provider と uid の両方がある場合" do
      it "trueを返すこと" do
        user = build(:user, :oauth)
        expect(user.oauth_user?).to be(true)
      end
    end

    context "provider のみある場合" do
      it "falseを返すこと" do
        user = build(:user, provider: "google_oauth2", uid: nil)
        expect(user.oauth_user?).to be(false)
      end
    end

    context "uid のみある場合" do
      it "falseを返すこと" do
        user = build(:user, provider: nil, uid: "123")
        expect(user.oauth_user?).to be(false)
      end
    end

    context "両方ない場合（通常のメール登録ユーザー）" do
      it "falseを返すこと" do
        user = build(:user)
        expect(user.oauth_user?).to be(false)
      end
    end
  end

  describe "コールバック" do
    describe "after_create :create_item_list" do
      it "ユーザー作成時に ItemList が生成されること" do
        expect { create(:user) }.to change(ItemList, :count).by(1)
      end

      it "生成された ItemList がユーザーに紐づいていること" do
        user = create(:user)
        expect(user.item_list).to be_present
        expect(user.item_list.listable).to eq(user)
      end
    end
  end

  describe "#cards_with_spots_grouped" do
    it "カードとスポットをカテゴリIDでグループ化して返すこと" do
      user = create(:user)
      card = create(:card, cardable: user, name: "京都旅行")
      category1 = create(:category)
      category2 = create(:category)
      create(:spot, card: card, category: category1, name: "金閣寺")
      create(:spot, card: card, category: category2, name: "抹茶カフェ")

      result = user.cards_with_spots_grouped

      expect(result.length).to eq(1)
      grouped_card, spots_by_category = result.first
      expect(grouped_card).to eq(card)
      expect(spots_by_category.keys).to contain_exactly(category1.id, category2.id)
      expect(spots_by_category[category1.id].map(&:name)).to eq([ "金閣寺" ])
      expect(spots_by_category[category2.id].map(&:name)).to eq([ "抹茶カフェ" ])
    end

    it "カードがない場合は空配列を返すこと" do
      user = create(:user)
      expect(user.cards_with_spots_grouped).to eq([])
    end
  end

  describe "member_ofメソッド" do
    context "ユーザーがグループのメンバーの場合" do
      it "member_ofはtrueを返すこと" do
        user = create(:user)
        group = create(:group)
        create(:group_membership, user: user, group: group)

        result = user.member_of?(group)
        expect(result).to be(true)
      end
    end

    context "ユーザーがグループのメンバーではない場合" do
      it "member_ofはfalseを返すこと" do
        user = create(:user)
        group = create(:group)
        # ユーザーとグループを作って、メンバーシップを作らない
        result = user.member_of?(group)
        expect(result).to be(false)
      end
    end
  end
end
