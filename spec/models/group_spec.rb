# == Schema Information
#
# Table name: groups
#
#  id                 :bigint           not null, primary key
#  invite_token       :string(64)       not null
#  name               :string(30)       not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  created_by_user_id :bigint           not null
#
# Indexes
#
#  index_groups_on_created_by_user_id  (created_by_user_id)
#  index_groups_on_invite_token        (invite_token) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (created_by_user_id => users.id)
#
require "rails_helper"

RSpec.describe Group, type: :model do
  describe "バリデーション" do
    describe "created_by_user_id" do
      context "存在する場合" do
        it "保存に成功すること" do
          group = build(:group)
          expect(group).to be_valid
        end
      end

      context "存在しない場合" do
        it "保存に失敗すること" do
          group = build(:group, created_by_user_id: nil)
          expect(group).not_to be_valid
        end
      end
    end

    describe "name" do
      context "存在する場合" do
        it "保存に成功すること" do
          group = build(:group)
          expect(group).to be_valid
        end
      end

      context "存在しない場合" do
        it "保存に失敗すること" do
          group = build(:group, name: nil)
          expect(group).not_to be_valid
        end
      end

      context "文字数が30文字以下の場合" do
        it "保存に成功すること" do
          group = build(:group, name: "a" * 30)
          expect(group).to be_valid
        end
      end

      context "文字数が31文字以上の場合" do
        it "保存に失敗すること" do
          group = build(:group, name: "a" * 31)
          expect(group).not_to be_valid
        end
      end
    end

    describe "invite_token" do
      context "自動生成される場合" do
        it "保存に成功すること" do
          group = build(:group)
          expect(group).to be_valid
        end
      end

      context "文字数が64文字以下の場合" do
        it "保存に成功すること" do
          group = build(:group, invite_token: "a" * 64)
          expect(group).to be_valid
        end
      end

      context "文字数が65文字以上の場合" do
        it "保存に失敗すること" do
          group = build(:group, invite_token: "a" * 65)
          expect(group).not_to be_valid
        end
      end

      context "既存データとの重複がない場合" do
        it "保存に成功すること" do
          # 他のグループを先に作成して、そのトークンとは違うことを確認
          create(:group)  # 既存データを作成
          group = build(:group)  # 新しいトークンで新規グループを作成
          expect(group).to be_valid
        end
      end

      context "既存データとの重複がある場合" do
        it "保存に失敗すること" do
          group1 = create(:group)
          group2 = build(:group, invite_token: group1.invite_token)
          expect(group2).not_to be_valid
        end
      end
    end
  end

  describe "コールバック" do
    describe "before_validation :generate_invite_token" do
      it "グループ作成前はトークンがない" do
        group = build(:group)
        expect(group.invite_token).to be_nil
      end

      it "グループ検証時にトークンが自動生成される" do
        group = build(:group)
        group.validate
        expect(group.invite_token).to be_present
      end

      it "既存グループの更新時にトークンが再生成されないこと" do
        group = create(:group)
        original_token = group.invite_token
        group.update(name: "新しい名前")
        expect(group.reload.invite_token).to eq(original_token)
      end
    end
  end

  describe "メソッド" do
    describe "#created_by?" do
      let(:creator) { create(:user) }
      let(:other_user) { create(:user) }
      let(:group) { create(:group, creator: creator) }

      context "グループを作成したユーザーの場合" do
        it "trueを返すこと" do
          expect(group.created_by?(creator)).to be(true)
        end
      end

      context "グループを作成していないユーザーの場合" do
        it "falseを返すこと" do
          expect(group.created_by?(other_user)).to be(false)
        end
      end

      context "nilが渡された場合" do
        it "falseを返すこと" do
          expect(group.created_by?(nil)).to be(false)
        end
      end
    end

    describe "#deletable_by?" do
      let(:creator) { create(:user) }
      let(:other_user) { create(:user) }
      let(:group) { create(:group, creator: creator) }

      it "作成者は削除可能であること" do
        expect(group.deletable_by?(creator)).to be(true)
      end

      it "作成者以外は削除不可であること" do
        expect(group.deletable_by?(other_user)).to be(false)
      end
    end

    describe "#cards_with_spots_grouped" do
      it "カードとスポットをカテゴリIDでグループ化して返すこと" do
        group = create(:group)
        card = create(:card, cardable: group)
        category = create(:category)
        create(:spot, card: card, category: category, name: "清水寺")

        result = group.cards_with_spots_grouped

        expect(result.length).to eq(1)
        grouped_card, spots_by_category = result.first
        expect(grouped_card).to eq(card)
        expect(spots_by_category[category.id].map(&:name)).to eq([ "清水寺" ])
      end

      it "カードがない場合は空配列を返すこと" do
        group = create(:group)
        expect(group.cards_with_spots_grouped).to eq([])
      end
    end
  end

  describe "スコープ" do
    describe ".recently_updated" do
      it "updated_atの降順で取得されること" do
        group_old = create(:group)
        group_new = create(:group)
        # updated_at を明示的に設定
        group_old.update_column(:updated_at, 1.day.ago)
        group_new.update_column(:updated_at, Time.current)

        result = Group.recently_updated
        expect(result.first).to eq(group_new)
        expect(result.last).to eq(group_old)
      end
    end

    describe ".with_memberships_and_schedule" do
      it "group_membershipsとscheduleを事前読み込みすること" do
        group = create(:group)
        create(:group_membership, group: group)

        loaded_group = Group.with_memberships_and_schedule.find(group.id)
        expect(loaded_group.association(:group_memberships)).to be_loaded
        expect(loaded_group.association(:schedule)).to be_loaded
      end
    end
  end
end
