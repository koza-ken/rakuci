# == Schema Information
#
# Table name: cards
#
#  id            :bigint           not null, primary key
#  cardable_type :string           not null
#  memo          :text
#  name          :string(50)       not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  cardable_id   :bigint           not null
#
# Indexes
#
#  index_cards_on_cardable_type_and_cardable_id  (cardable_type,cardable_id)
#
require "rails_helper"

RSpec.describe Card, type: :model do
  describe "バリデーション" do
    describe "name" do
      context "nameが存在しない場合" do
        it "保存に失敗すること" do
          card = build(:card, name: nil)
          expect(card).not_to be_valid
        end
      end

      context "文字数が50文字以下の場合" do
        it "保存に成功すること" do
          card = build(:card, name: "a" * 50)
          expect(card).to be_valid
        end
      end

      context "文字数が51文字以上の場合" do
        it "保存に失敗すること" do
          card = build(:card, name: "a" * 51)
          expect(card).not_to be_valid
        end
      end
    end

    # ポリモーフィック関連のバリデーション
    describe "cardable（ポリモーフィック関連）" do
      context "個人カードの場合" do
        it "保存に成功すること" do
          card = build(:card, :for_user)
          expect(card).to be_valid
          expect(card.cardable_type).to eq("User")
        end
      end

      context "グループカードの場合" do
        it "保存に成功すること" do
          card = build(:card, :for_group)
          expect(card).to be_valid
          expect(card.cardable_type).to eq("Group")
        end
      end
    end
  end

  describe "メソッド" do
    describe "#accessible?メソッド" do
      context "ログインユーザーの場合" do
        context "グループカードの場合" do
          it "グループメンバーならtrueを返すこと" do
            user = create(:user)
            group = create(:group)
            create(:group_membership, user: user, group: group)
            card = create(:card, :for_group, cardable: group)

            expect(card.accessible?(user: user, guest_group_ids: [])).to be true
          end

          it "グループメンバーでなければfalseを返すこと" do
            user = create(:user)
            card = create(:card, :for_group)

            expect(card.accessible?(user: user, guest_group_ids: [])).to be false
          end
        end

        context "個人カードの場合" do
          it "作成者ならtrueを返すこと" do
            user = create(:user)
            card = create(:card, :for_user, cardable: user)

            expect(card.accessible?(user: user, guest_group_ids: [])).to be true
          end

          it "作成者でなければfalseを返すこと" do
            user1 = create(:user)
            user2 = create(:user)
            card = create(:card, :for_user, cardable: user1)

            expect(card.accessible?(user: user2, guest_group_ids: [])).to be false
          end
        end
      end

      context "ゲストの場合" do
        context "グループカードの場合" do
          it "参加済みグループのカードならtrueを返すこと" do
            group = create(:group)
            card = create(:card, :for_group, cardable: group)

            expect(card.accessible?(user: nil, guest_group_ids: [ group.id ])).to be true
          end

          it "参加していないグループのカードならfalseを返すこと" do
            group = create(:group)
            card = create(:card, :for_group, cardable: group)

            expect(card.accessible?(user: nil, guest_group_ids: [ 999 ])).to be false
          end
        end

        context "個人カードの場合" do
          it "falseを返すこと" do
            card = create(:card, :for_user)

            expect(card.accessible?(user: nil, guest_group_ids: [ 1, 2, 3 ])).to be false
          end
        end
      end
    end

    describe "#group_card?メソッド" do
      context "グループカードの場合" do
        it "trueを返すこと" do
          card = create(:card, :for_group)
          expect(card.group_card?).to be true
        end
      end

      context "個人カードの場合" do
        it "falseを返すこと" do
          card = create(:card, :for_user)
          expect(card.group_card?).to be false
        end
      end
    end

    describe "#liked_by?メソッド" do
      context "メンバーシップがいいねしている場合" do
        it "trueを返すこと" do
          card = create(:card)
          membership = create(:group_membership)
          create(:like, card: card, group_membership: membership)

          expect(card.liked_by?(membership)).to be true
        end
      end

      context "メンバーシップがいいねしていない場合" do
        it "falseを返すこと" do
          card = create(:card)
          membership = create(:group_membership)

          expect(card.liked_by?(membership)).to be false
        end
      end

      context "メンバーシップがnilの場合" do
        it "falseを返すこと" do
          card = create(:card)

          expect(card.liked_by?(nil)).to be false
        end
      end
    end
  end
end
