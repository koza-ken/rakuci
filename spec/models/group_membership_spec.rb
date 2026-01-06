# == Schema Information
#
# Table name: group_memberships
#
#  id             :bigint           not null, primary key
#  group_nickname :string(20)
#  guest_token    :string(64)
#  role           :string           default("member"), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  group_id       :bigint           not null
#  user_id        :bigint
#
# Indexes
#
#  index_group_memberships_on_group_id                     (group_id)
#  index_group_memberships_on_group_id_and_group_nickname  (group_id,group_nickname) UNIQUE
#  index_group_memberships_on_guest_token                  (guest_token)
#  index_group_memberships_on_user_id                      (user_id)
#  index_group_memberships_on_user_id_and_group_id         (user_id,group_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (group_id => groups.id)
#  fk_rails_...  (user_id => users.id)
#
require "rails_helper"

RSpec.describe GroupMembership, type: :model do
  describe "バリデーション" do
    describe "group_nickname" do
      context "値が存在しない場合" do
        it "保存に失敗すること" do
          membership = build(:group_membership, group_nickname: nil)
          expect(membership).not_to be_valid
        end
      end

      context "値がすでにグループに存在している場合" do
        it "保存に失敗すること" do
          group = create(:group)
          membership1 = create(:group_membership, group: group, group_nickname: "nickname")
          membership2 = build(:group_membership, group: group, group_nickname: "nickname")
          expect(membership2).not_to be_valid
        end
      end

      context "異なるニックネームで別のグループに参加する場合" do
        it "保存に成功する" do
          user = create(:user)
          group1 = create(:group)
          group2 = create(:group)
          membership1 = create(:group_membership, group: group1)
          membership2 = build(:group_membership, group: group2)
          expect(membership2).to be_valid
        end
      end

      context "文字数が21文字以上の場合" do
        it "保存に失敗すること" do
          membership = build(:group_membership, group_nickname: "a" * 21)
          expect(membership).not_to be_valid
        end
      end
    end

    describe "guest_token" do
      context "値が空の場合" do
        it "保存に成功すること" do
          user = create(:user)
          membership = build(:group_membership, guest_token: nil)
          expect(membership).to be_valid
        end
      end

      context "文字数が64文字以下の場合" do
        it "保存に成功すること" do
          membership = build(:group_membership, guest_token: "a" * 64)
          expect(membership).to be_valid
        end
      end

      context "文字数が65文字以上の場合" do
        it "保存に失敗すること" do
          membership = build(:group_membership, guest_token: "a" * 65)
          expect(membership).not_to be_valid
        end
      end
    end

    # user_idかguest_tokenのどちらかがあるかを確認するカスタムバリデーション
    describe "must_have_user_or_guest_token" do
      context "user_idだけがある場合" do
        it "保存に成功すること" do
          user = create(:user)
          membership = build(:group_membership, guest_token: nil)
          expect(membership).to be_valid
        end
      end

      context "guest_tokenだけがある場合" do
        it "保存に成功すること" do
          membership = build(:group_membership, :guest)
          expect(membership).to be_valid
        end
      end

      context "user_idとguest_tokenの両方がある場合" do
        it "保存に成功すること" do
          membership = build(:group_membership, guest_token: "guest_token")
          expect(membership).to be_valid
        end
      end

      context "user_idとguest_tokenの両方がない場合" do
        it "保存に失敗すること" do
          membership = build(:group_membership, user_id: nil, guest_token: nil)
          expect(membership).not_to be_valid
        end
      end
    end
  end

  describe "メソッド" do
    # ログインユーザーがグループのメンバーか確認するメソッド
    describe ".user_member?" do
      context "ユーザーがグループのメンバーの場合" do
        it "trueを返すこと" do
          membership = create(:group_membership)

          result = described_class.user_member?(membership.user, membership.group)
          expect(result).to be(true)
        end
      end

      context "ユーザーがグループのメンバーではない場合" do
        it "falseを返すこと" do
          user = create(:user)
          group = create(:group)
          result = described_class.user_member?(user, group)
          expect(result).to be(false)
        end
      end
    end

    # ゲストトークンがグループのメンバーか確認するメソッド
    describe ".guest_member?" do
      context "guest_tokenが空の場合" do
        it "falseを返すこと" do
          result = described_class.guest_member?(nil, create(:group))
          expect(result).to be(false)
        end
      end

      context "guest_tokenがグループに存在する場合" do
        it "trueを返すこと" do
          membership = create(:group_membership, :guest)
          result = described_class.guest_member?(membership.guest_token, membership.group)
          expect(result).to be(true)
        end
      end

      context "guest_tokenが存在しないか、異なるグループの場合" do
        it "falseを返すこと" do
          membership = create(:group_membership, :guest)
          other_group = create(:group)
          result = described_class.guest_member?(membership.guest_token, other_group)
          expect(result).to be(false)
        end
      end
    end

    # ゲストトークンを生成するメソッド
    describe "#generate_guest_token" do
      context "既にトークンを持っている場合" do
        it "既存のトークンを返すこと" do
          membership = create(:group_membership, :guest)
          original_token = membership.guest_token

          membership.generate_guest_token
          expect(membership.guest_token).to eq(original_token)
        end
      end

      context "トークンを持っていない場合" do
        it "トークンを生成すること" do
          membership = build(:group_membership, guest_token: nil, user_id: create(:user).id)
          token = membership.generate_guest_token

          expect(token).not_to be_nil
          expect(token).to match(/^[A-Za-z0-9_-]+$/)
        end
      end
    end
  end
end
