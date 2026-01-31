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
    end
  end
end
