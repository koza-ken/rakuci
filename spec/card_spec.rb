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

    # userかgroupのどちらか一方に関連づいているかのバリデーション
    describe "must_belong_to_user_or_group" do
      context "user_idがあってgroup_idがない場合" do
        it "保存に成功すること" do
          card = build(:card, :for_user)
          expect(card).to be_valid
        end
      end
      context "user_idがなくてgroup_idがある場合" do
        it "保存に成功すること" do
          card = build(:card, :for_group)
          expect(card).to be_valid
        end
      end
      context "user_idとgroup_idの両方がある場合" do
        it "保存に失敗すること" do
          group = create(:group)
          card = build(:card, group_id: group.id)
          expect(card).not_to be_valid
        end
      end
      context "user_idとgroup_idの両方がない場合" do
        it "保存に失敗すること" do
          card = build(:card, user_id: nil, group_id: nil)
          expect(card).not_to be_valid
        end
      end
    end
  end

  describe "メソッド" do

    describe ".build_forメソッド" do
      context "group_idがある場合" do
        it "グループカードが作成されること（ユーザーに紐づけない）" do
          user = create(:user)
          group = create(:group)
          attributes = { name: "test", group_id: group.id }
          card = Card.build_for(user: user, attributes: attributes)
          expect(card.group_id).to eq(group.id)
          expect(card.user_id).to be_nil
        end
      end
      context "group_idがない場合" do
        it "個人カードが作成されること（ユーザーに紐づける）" do
          user = create(:user)
          attributes = { name: "test" }
          card = Card.build_for(user: user, attributes: attributes)
          expect(card.user_id).to eq(user.id)
        end
      end
      context "userがなく、group_idもない場合" do
        it "エラーが発生すること" do
          attributes = { name: "test" }
          expect { Card.build_for(user: nil, attributes: attributes) }
            .to raise_error(ArgumentError, "個人用カードを作成するにはログインが必要です")
        end
      end
    end

    describe "#accessible_by_user?メソッド" do
      context "グループカードの場合" do
        context "ユーザーがグループメンバーの場合" do
          it "trueを返すこと" do
            user = create(:user)
            group = create(:group)
            create(:group_membership, user: user, group: group)
            card = create(:card, :for_group, user: user, group: group)

            expect(card.accessible_by_user?(user)).to be true
          end
        end
        context "ユーザーがグループメンバーではない場合" do
          it "falseを返すこと" do
            user = create(:user)
            group = create(:group)
            card = create(:card, :for_group)

            expect(card.accessible_by_user?(user)).to be false
          end
        end
      end

      context "個人カードの場合" do
        context "ユーザーが作成者の場合" do
          it "trueを返すこと" do
            user = create(:user)
            card = create(:card, :for_user, user: user)

            expect(card.accessible_by_user?(user)).to be true
          end
        end
        context "ユーザーが作成者ではない場合" do
          it "falseを返すこと" do
            user1 = create(:user)
            user2 = create(:user)
            card = create(:card, :for_user, user: user1)

            expect(card.accessible_by_user?(user2)).to be false
          end
        end
      end
    end

    describe "#accessible_by_guest?メソッド" do
      context "個人カードの場合" do
        it "falseを返すこと" do
          card = create(:card, :for_user)
          expect(card.accessible_by_guest?([1, 2, 3])).to be false
        end
      end

      context "グループカードの場合" do
        context "ゲストユーザーが参加できるグループidの配列（guest_group_ids）にグループが含まれる場合" do
          it "trueを返すこと" do
            group = create(:group)
            card = create(:card, :for_group, group: group)
            guest_group_ids = [group.id, 2, 3]

            expect(card.accessible_by_guest?(guest_group_ids)).to be true
          end
        end
        context "ゲストユーザーが参加できるグループidの配列（guest_group_ids）にグループが含まれない場合" do
          it "falseを返すこと" do
            group = create(:group)
            card = create(:card, :for_group, group: group)
            guest_group_ids = [999, 1000, 1001]

            expect(card.accessible_by_guest?(guest_group_ids)).to be false
          end
        end
      end
    end


    describe "#accessible?メソッド" do
      context "ログインユーザーがアクセスできる場合" do
        it "trueを返すこと" do
          user = create(:user)
          card = create(:card, :for_user, user: user)

          expect(card.accessible?(user: user, guest_group_ids: [])).to be true
        end
      end

      context "ログインユーザーがアクセスできない場合" do
        it "falseを返すこと" do
          user1 = create(:user)
          user2 = create(:user)
          card = create(:card, :for_user, user: user1)

          expect(card.accessible?(user: user2, guest_group_ids: [])).to be false
        end
      end

      context "ゲストがアクセスできる場合" do
        it "trueを返すこと" do
          group = create(:group)
          card = create(:card, :for_group, group: group)

          expect(card.accessible?(user: nil, guest_group_ids: [group.id])).to be true
        end
      end

      context "ゲストがアクセスできない場合" do
        it "falseを返すこと" do
          group = create(:group)
          card = create(:card, :for_group, group: group)

          expect(card.accessible?(user: nil, guest_group_ids: [999])).to be false
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
