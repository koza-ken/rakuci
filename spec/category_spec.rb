require "rails_helper"

RSpec.describe Category, type: :model do
  describe "バリデーション" do
    describe "name" do
      context "nameが存在しない場合" do
        it "保存に失敗すること" do
          category = build(:category, name: nil)
          expect(category).not_to be_valid
        end
      end
      context "文字数が20文字以下の場合" do
        it "保存に成功すること" do
          category = build(:category, name: "a" * 20)
          expect(category).to be_valid
        end
      end
      context "文字数が21文字以上の場合" do
        it "保存に失敗すること" do
          category = build(:category, name: "a" * 21)
          expect(category).not_to be_valid
        end
      end
    end

    describe "display_order" do
      context "display_orderが存在する場合" do
        it "保存に成功すること" do
          category = build(:category, display_order: 1)
          expect(category).to be_valid
        end
      end
      context "display_orderが存在しない場合" do
        it "保存に失敗すること" do
          category = build(:category, display_order: nil)
          expect(category).not_to be_valid
        end
      end
      context "既存データとの重複がない場合" do
        it "保存に成功すること" do
          create(:category, display_order: 1)
          category = build(:category, display_order: 2)
          expect(category).to be_valid
        end
      end
      context "既存データとの重複がある場合" do
        it "保存に失敗すること" do
          category1 = create(:category, display_order: 1)
          category2 = build(:category, display_order: 1)
          expect(category2).not_to be_valid
        end
      end
    end
  end

  describe "メソッド" do
    describe "#icon_partial" do
      context "name が「観光地」の場合" do
        it "card_icon_sightseeing を返すこと" do
          category = build(:category, name: "観光地")
          expect(category.icon_partial).to eq("shared/icon/card_icon_sightseeing")
        end
      end

      context "name が「グルメ」の場合" do
        it "card_icon_gourmet を返すこと" do
          category = build(:category, name: "グルメ")
          expect(category.icon_partial).to eq("shared/icon/card_icon_gourmet")
        end
      end

      context "name が「体験」の場合" do
        it "card_icon_activity を返すこと" do
          category = build(:category, name: "体験")
          expect(category.icon_partial).to eq("shared/icon/card_icon_activity")
        end
      end

      context "name が「買い物」の場合" do
        it "card_icon_shopping を返すこと" do
          category = build(:category, name: "買い物")
          expect(category.icon_partial).to eq("shared/icon/card_icon_shopping")
        end
      end

      context "name が上記以外の場合" do
        it "nil を返すこと" do
          category = build(:category, name: "その他")
          expect(category.icon_partial).to be_nil
        end
      end
    end
  end
end
