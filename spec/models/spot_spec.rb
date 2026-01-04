require "rails_helper"

RSpec.describe Spot, type: :model do
  describe "バリデーション" do
    describe "name" do
      context "nameが存在しない場合" do
        it "保存に失敗すること" do
          spot = build(:spot, name: nil)
          expect(spot).not_to be_valid
        end
      end

      context "文字数が50文字以下の場合" do
        it "保存に成功すること" do
          spot = build(:spot, name: "a" * 50)
          expect(spot).to be_valid
        end
      end

      context "文字数が51文字以上の場合" do
        it "保存に失敗すること" do
          spot = build(:spot, name: "a" * 51)
          expect(spot).not_to be_valid
        end
      end
    end

    describe "phone_number" do
      context "値が空の場合" do
        it "保存に成功すること" do
          spot = build(:spot, phone_number: nil)
          expect(spot).to be_valid
        end
      end

      context "文字数が20文字以下の場合" do
        it "保存に成功すること" do
          spot = build(:spot, phone_number: "a" * 20)
          expect(spot).to be_valid
        end
      end

      context "文字数が21文字以上の場合" do
        it "保存に失敗すること" do
          spot = build(:spot, phone_number: "a" * 21)
          expect(spot).not_to be_valid
        end
      end
    end

    describe "website_url" do
      context "値が空の場合" do
        it "保存に成功すること" do
          spot = build(:spot, website_url: nil)
          expect(spot).to be_valid
        end
      end

      context "有効な HTTP URL の場合" do
        it "保存に成功すること" do
          spot = build(:spot, website_url: "http://example.com")
          expect(spot).to be_valid
        end
      end

      context "有効な HTTPS URL の場合" do
        it "保存に成功すること" do
          spot = build(:spot, website_url: "https://example.com")
          expect(spot).to be_valid
        end
      end

      context "JavaScript プロトコルの場合" do
        it "保存に失敗すること" do
          spot = build(:spot, website_url: "javascript:alert('xss')")
          expect(spot).not_to be_valid
        end
      end

      context "不正なスキーム（ftp）の場合" do
        it "保存に失敗すること" do
          spot = build(:spot, website_url: "ftp://example.com")
          expect(spot).not_to be_valid
        end
      end
    end

    describe "google_place_id" do
      context "値が空の場合" do
        it "保存に成功すること" do
          spot = build(:spot, google_place_id: nil)
          expect(spot).to be_valid
        end
      end

      context "値が同じカードに存在しない場合" do
        it "保存に成功すること" do
          card = create(:card)
          spot = build(:spot, card: card, google_place_id: "place_123")
          expect(spot).to be_valid
        end
      end

      context "値が同じカードに存在する場合" do
        it "保存に失敗すること" do
          card = create(:card)
          spot1 = create(:spot, card: card, google_place_id: "place_123")
          spot2 = build(:spot, card: card, google_place_id: "place_123")
          expect(spot2).not_to be_valid
        end
      end

      context "値が異なるカードに存在する場合" do
        it "保存に成功すること" do
          card1 = create(:card)
          card2 = create(:card)
          spot1 = create(:spot, card: card1, google_place_id: "place_123")
          spot2 = build(:spot, card: card2, google_place_id: "place_123")
          expect(spot2).to be_valid
        end
      end
    end
  end
end
