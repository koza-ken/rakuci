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
