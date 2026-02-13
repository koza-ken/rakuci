# == Schema Information
#
# Table name: group_memberships
#
#  id                 :bigint           not null, primary key
#  group_nickname     :string(20)
#  guest_token_digest :string(64)
#  role               :string           default("member"), not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  group_id           :bigint           not null
#  user_id            :bigint
#
# Indexes
#
#  index_group_memberships_on_group_id                     (group_id)
#  index_group_memberships_on_group_id_and_group_nickname  (group_id,group_nickname) UNIQUE
#  index_group_memberships_on_guest_token_digest           (guest_token_digest)
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

    describe "guest_token_digest" do
      context "値が空の場合" do
        it "保存に成功すること" do
          user = create(:user)
          membership = build(:group_membership, guest_token_digest: nil)
          expect(membership).to be_valid
        end
      end

      context "文字数が64文字以下の場合" do
        it "保存に成功すること" do
          membership = build(:group_membership, guest_token_digest: "a" * 64)
          expect(membership).to be_valid
        end
      end

      context "文字数が65文字以上の場合" do
        it "保存に失敗すること" do
          membership = build(:group_membership, guest_token_digest: "a" * 65)
          expect(membership).not_to be_valid
        end
      end
    end

    # user_idかguest_token_digestのどちらかがあるかを確認するカスタムバリデーション
    describe "must_have_user_or_guest_token_digest" do
      context "user_idだけがある場合" do
        it "保存に成功すること" do
          user = create(:user)
          membership = build(:group_membership, guest_token_digest: nil)
          expect(membership).to be_valid
        end
      end

      context "guest_token_digestだけがある場合" do
        it "保存に成功すること" do
          membership = build(:group_membership, :guest)
          expect(membership).to be_valid
        end
      end

      context "user_idとguest_token_digestの両方がある場合" do
        it "保存に成功すること" do
          membership = build(:group_membership, guest_token_digest: Digest::SHA256.hexdigest("guest_token"))
          expect(membership).to be_valid
        end
      end

      context "user_idとguest_token_digestの両方がない場合" do
        it "保存に失敗すること" do
          membership = build(:group_membership, user_id: nil, guest_token_digest: nil)
          expect(membership).not_to be_valid
        end
      end
    end
  end

  describe "enum" do
    describe "role" do
      it "memberロールが設定できること" do
        membership = create(:group_membership, role: "member")
        expect(membership).to be_member
      end

      it "ownerロールが設定できること" do
        membership = create(:group_membership, role: "owner")
        expect(membership).to be_owner
      end
    end
  end

  describe "スコープ" do
    describe ".guests" do
      it "user_idがnilのメンバーのみ取得すること" do
        group = create(:group)
        registered = create(:group_membership, group: group)
        guest = create(:group_membership, :guest, group: group)

        result = GroupMembership.guests
        expect(result).to include(guest)
        expect(result).not_to include(registered)
      end
    end
  end

  describe "メソッド" do
    describe "#guest?" do
      it "user_idがnilならtrueを返すこと" do
        membership = build(:group_membership, :guest)
        expect(membership.guest?).to be(true)
      end

      it "user_idがあればfalseを返すこと" do
        membership = build(:group_membership)
        expect(membership.guest?).to be(false)
      end
    end

    describe "#deletable_by?" do
      let(:creator) { create(:user) }
      let(:group) { create(:group, creator: creator) }

      context "グループ作成者がmemberロールのメンバーを削除する場合" do
        it "trueを返すこと" do
          membership = create(:group_membership, group: group, role: "member")
          expect(membership.deletable_by?(creator)).to be(true)
        end
      end

      context "グループ作成者がownerロールのメンバーを削除する場合" do
        it "falseを返すこと（ownerは削除不可）" do
          membership = create(:group_membership, group: group, role: "owner")
          expect(membership.deletable_by?(creator)).to be(false)
        end
      end

      context "作成者以外のユーザーがメンバーを削除する場合" do
        it "falseを返すこと" do
          other_user = create(:user)
          membership = create(:group_membership, group: group, role: "member")
          expect(membership.deletable_by?(other_user)).to be(false)
        end
      end
    end

    describe "#attach_user_or_guest_token" do
      let(:group) { create(:group) }

      context "ログインユーザーの場合" do
        it "user_idが設定され、nilを返すこと" do
          user = create(:user)
          membership = create(:group_membership, :guest, group: group)
          result = membership.attach_user_or_guest_token(user)

          expect(result).to be_nil
          expect(membership.reload.user_id).to eq(user.id)
        end
      end

      context "新規ゲスト（digestなし）の場合" do
        it "平文トークンを返し、digestが保存されること" do
          membership = group.group_memberships.build(
            group_nickname: "ゲスト太郎", role: "member"
          )
          result = membership.attach_user_or_guest_token(nil)

          expect(result).to be_a(String)
          expect(result).to match(/^[A-Za-z0-9_-]+$/)
          expect(membership.guest_token_digest).to eq(Digest::SHA256.hexdigest(result))
        end
      end

      context "既存ゲスト（digest済み）の場合" do
        it "新しい平文トークンを返し、digestが更新されること" do
          membership = create(:group_membership, :guest, group: group)
          original_digest = membership.guest_token_digest
          result = membership.attach_user_or_guest_token(nil)

          expect(result).to be_a(String)
          expect(membership.reload.guest_token_digest).not_to eq(original_digest)
        end
      end
    end

    # 平文トークンでグループのメンバーか確認するメソッド
    describe ".guest_member_by_token?" do
      context "トークンが空の場合" do
        it "falseを返すこと" do
          result = described_class.guest_member_by_token?(nil, create(:group))
          expect(result).to be(false)
        end
      end

      context "正しい平文トークンの場合" do
        it "trueを返すこと" do
          raw_token = "test_raw_token_abc123"
          group = create(:group)
          create(:group_membership, :guest, group: group, guest_token_digest: Digest::SHA256.hexdigest(raw_token))
          result = described_class.guest_member_by_token?(raw_token, group)
          expect(result).to be(true)
        end
      end

      context "不正な平文トークンの場合" do
        it "falseを返すこと" do
          raw_token = "test_raw_token_abc123"
          group = create(:group)
          create(:group_membership, :guest, group: group, guest_token_digest: Digest::SHA256.hexdigest(raw_token))
          result = described_class.guest_member_by_token?("wrong_token", group)
          expect(result).to be(false)
        end
      end

      context "異なるグループの場合" do
        it "falseを返すこと" do
          raw_token = "test_raw_token_abc123"
          group = create(:group)
          other_group = create(:group)
          create(:group_membership, :guest, group: group, guest_token_digest: Digest::SHA256.hexdigest(raw_token))
          result = described_class.guest_member_by_token?(raw_token, other_group)
          expect(result).to be(false)
        end
      end
    end

    # ゲストトークンを生成するメソッド
    describe "#generate_guest_token" do
      context "既にdigestを持っている場合" do
        it "新しいトークンを生成しないこと" do
          membership = create(:group_membership, :guest)
          original_digest = membership.guest_token_digest
          membership.generate_guest_token
          expect(membership.guest_token_digest).to eq(original_digest)
        end
      end

      context "digestを持っていない場合" do
        it "平文トークンを返し、digestを保存すること" do
          membership = build(:group_membership, guest_token_digest: nil, user_id: create(:user).id)
          raw_token = membership.generate_guest_token
          expect(raw_token).not_to be_nil
          expect(raw_token).to match(/^[A-Za-z0-9_-]+$/)
          expect(membership.guest_token_digest).to eq(Digest::SHA256.hexdigest(raw_token))
        end
      end
    end

    # ゲストトークンを再生成するメソッド
    describe "#regenerate_guest_token" do
      it "新しいトークンを生成し、digestを更新すること" do
        membership = create(:group_membership, :guest)
        original_digest = membership.guest_token_digest
        raw_token = membership.regenerate_guest_token
        expect(raw_token).not_to be_nil
        expect(membership.guest_token_digest).not_to eq(original_digest)
        expect(membership.guest_token_digest).to eq(Digest::SHA256.hexdigest(raw_token))
      end
    end

    # SHA256 digest 生成メソッド
    describe ".digest" do
      it "SHA256 hexdigestを返すこと" do
        expect(described_class.digest("test")).to eq(Digest::SHA256.hexdigest("test"))
      end
    end

    # 平文トークンからmembershipを検索するメソッド
    describe ".find_by_raw_token" do
      context "正しい平文トークンの場合" do
        it "membershipを返すこと" do
          raw_token = "test_token_xyz"
          group = create(:group)
          membership = create(:group_membership, :guest, group: group, guest_token_digest: Digest::SHA256.hexdigest(raw_token))
          found = described_class.find_by_raw_token(raw_token, group_id: group.id)
          expect(found).to eq(membership)
        end
      end

      context "トークンが空の場合" do
        it "nilを返すこと" do
          expect(described_class.find_by_raw_token(nil, group_id: 1)).to be_nil
        end
      end
    end
  end
end
