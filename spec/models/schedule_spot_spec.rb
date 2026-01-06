# == Schema Information
#
# Table name: schedule_spots
#
#  id                    :bigint           not null, primary key
#  day_number            :integer          not null
#  end_time              :time
#  global_position       :integer          not null
#  is_custom_entry       :boolean          default(FALSE), not null
#  memo                  :text
#  snapshot_address      :string
#  snapshot_name         :string
#  snapshot_phone_number :string
#  snapshot_website_url  :string
#  start_time            :time
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  google_place_id       :string
#  schedule_id           :bigint           not null
#  snapshot_category_id  :integer
#  spot_id               :bigint
#
# Indexes
#
#  index_schedule_spots_on_spot_id  (spot_id)
#  index_ss_on_schedule_and_day     (schedule_id,day_number)
#
# Foreign Keys
#
#  fk_rails_...  (schedule_id => schedules.id)
#  fk_rails_...  (spot_id => spots.id)
#
require "rails_helper"

RSpec.describe ScheduleSpot, type: :model do
  describe "バリデーション" do
    describe "day_number" do
      context "値が存在する場合" do
        it "保存に成功すること" do
          schedule_spot = build(:schedule_spot, day_number: 1)
          expect(schedule_spot).to be_valid
        end
      end

      context "値が存在しない場合" do
        it "保存に失敗すること" do
          schedule_spot = build(:schedule_spot, day_number: nil)
          expect(schedule_spot).not_to be_valid
        end
      end

      context "値が0以下の場合" do
        it "保存に失敗すること" do
          schedule_spot = build(:schedule_spot, day_number: 0)
          expect(schedule_spot).not_to be_valid
        end
      end
    end

    # global_position は acts_as_list が自動で管理するためバリデーションテスト不要

    describe "snapshot_name" do
      context "文字数が50文字以下の場合" do
        it "保存に成功すること" do
          schedule_spot = build(:schedule_spot, snapshot_name: "a" * 50)
          expect(schedule_spot).to be_valid
        end
      end

      context "文字数が51文字以上の場合" do
        it "保存に失敗すること" do
          schedule_spot = build(:schedule_spot, snapshot_name: "a" * 51)
          expect(schedule_spot).not_to be_valid
        end
      end
    end

    describe "snapshot_address" do
      context "文字数が255文字以下の場合" do
        it "保存に成功すること" do
          schedule_spot = build(:schedule_spot, snapshot_address: "a" * 255)
          expect(schedule_spot).to be_valid
        end
      end

      context "文字数が256文字以上の場合" do
        it "保存に失敗すること" do
          schedule_spot = build(:schedule_spot, snapshot_address: "a" * 256)
          expect(schedule_spot).not_to be_valid
        end
      end
    end

    describe "snapshot_phone_number" do
      context "文字数が20文字以下の場合" do
        it "保存に成功すること" do
          schedule_spot = build(:schedule_spot, snapshot_phone_number: "a" * 20)
          expect(schedule_spot).to be_valid
        end
      end

      context "文字数が21文字以上の場合" do
        it "保存に失敗すること" do
          schedule_spot = build(:schedule_spot, snapshot_phone_number: "a" * 21)
          expect(schedule_spot).not_to be_valid
        end
      end
    end

    describe "snapshot_website_url" do
      context "値が空の場合" do
        it "保存に成功すること" do
          schedule_spot = build(:schedule_spot, snapshot_website_url: nil)
          expect(schedule_spot).to be_valid
        end
      end

      context "有効な HTTP URL の場合" do
        it "保存に成功すること" do
          schedule_spot = build(:schedule_spot, snapshot_website_url: "http://example.com")
          expect(schedule_spot).to be_valid
        end
      end

      context "有効な HTTPS URL の場合" do
        it "保存に成功すること" do
          schedule_spot = build(:schedule_spot, snapshot_website_url: "https://example.com")
          expect(schedule_spot).to be_valid
        end
      end

      context "JavaScript プロトコルの場合" do
        it "保存に失敗すること" do
          schedule_spot = build(:schedule_spot, snapshot_website_url: "javascript:alert('xss')")
          expect(schedule_spot).not_to be_valid
        end
      end

      context "不正なスキーム（ftp）の場合" do
        it "保存に失敗すること" do
          schedule_spot = build(:schedule_spot, snapshot_website_url: "ftp://example.com")
          expect(schedule_spot).not_to be_valid
        end
      end

      context "文字数が500文字以下の場合" do
        it "保存に成功すること" do
          schedule_spot = build(:schedule_spot, snapshot_website_url: "https://example.com" + ("a" * 481))
          expect(schedule_spot).to be_valid
        end
      end

      context "文字数が501文字以上の場合" do
        it "保存に失敗すること" do
          schedule_spot = build(:schedule_spot, snapshot_website_url: "https://example.com" + ("a" * 482))
          expect(schedule_spot).not_to be_valid
        end
      end
    end

    describe "end_time" do
      context "start_timeとend_timeが両方空の場合" do
        it "保存に成功すること" do
          schedule_spot = build(:schedule_spot, start_time: nil, end_time: nil)
          expect(schedule_spot).to be_valid
        end
      end

      context "start_timeがあり、end_timeが空の場合" do
        it "保存に成功すること" do
          schedule_spot = build(:schedule_spot, start_time: "10:00", end_time: nil)
          expect(schedule_spot).to be_valid
        end
      end

      context "end_timeがstart_timeより後の場合" do
        it "保存に成功すること" do
          schedule_spot = build(:schedule_spot, start_time: "10:00", end_time: "11:00")
          expect(schedule_spot).to be_valid
        end
      end

      context "end_timeがstart_timeと同じ場合" do
        it "保存に失敗すること" do
          schedule_spot = build(:schedule_spot, start_time: "10:00", end_time: "10:00")
          expect(schedule_spot).not_to be_valid
        end
      end

      context "end_timeがstart_timeより前の場合" do
        it "保存に失敗すること" do
          schedule_spot = build(:schedule_spot, start_time: "11:00", end_time: "10:00")
          expect(schedule_spot).not_to be_valid
        end
      end
    end

    describe "spot_or_custom_entry_valid" do
      context "is_custom_entryがfalseで、spot_idがある場合" do
        it "保存に成功すること" do
          spot = create(:spot)
          schedule_spot = build(:schedule_spot, spot_id: spot.id, is_custom_entry: false)
          expect(schedule_spot).to be_valid
        end
      end

      context "is_custom_entryがtrueで、spot_idがない場合" do
        it "保存に成功すること" do
          schedule_spot = build(:schedule_spot, :custom, is_custom_entry: true)
          expect(schedule_spot).to be_valid
        end
      end

      context "is_custom_entryがtrueで、spot_idがある場合" do
        it "保存に失敗すること" do
          spot = create(:spot)
          schedule_spot = build(:schedule_spot, :custom, spot_id: spot.id, is_custom_entry: true)
          expect(schedule_spot).not_to be_valid
        end
      end

      context "is_custom_entryがfalseで、spot_idがない場合" do
        it "保存に失敗すること" do
          schedule_spot = build(:schedule_spot, spot_id: nil, is_custom_entry: false)
          expect(schedule_spot).not_to be_valid
        end
      end

      context "is_custom_entryがtrueで、snapshot_nameが空の場合" do
        it "保存に失敗すること" do
          schedule_spot = build(:schedule_spot, :custom, snapshot_name: nil, is_custom_entry: true)
          expect(schedule_spot).not_to be_valid
        end
      end
    end
  end

  describe "メソッド" do
    describe "#display_name" do
      context "snapshot_nameが存在する場合" do
        it "snapshot_nameを返すこと" do
          schedule_spot = build(:schedule_spot, snapshot_name: "Custom Name")
          expect(schedule_spot.display_name).to eq("Custom Name")
        end
      end

      context "snapshot_nameが空の場合" do
        context "spotが存在する場合" do
          it "spot.nameを返すこと" do
            spot = create(:spot, name: "Spot Name")
            schedule_spot = build(:schedule_spot, snapshot_name: "", spot: spot)
            expect(schedule_spot.display_name).to eq("Spot Name")
          end
        end

        context "spotが存在しない場合" do
          it "「予定」を返すこと" do
            schedule_spot = build(:schedule_spot, snapshot_name: "", spot: nil)
            expect(schedule_spot.display_name).to eq("予定")
          end
        end
      end
    end

    describe ".create_from_spot" do
      context "spotオブジェクトを渡した場合" do
        it "schedule_spotが作成されること" do
          schedule = create(:schedule)
          spot = create(:spot)
          schedule_spot = described_class.create_from_spot(schedule, spot, day_number: 2)

          expect(schedule_spot.spot_id).to eq(spot.id)
          expect(schedule_spot.day_number).to eq(2)
          expect(schedule_spot.is_custom_entry).to be false
          expect(schedule_spot.snapshot_name).to eq(spot.name)
          expect(schedule_spot.snapshot_address).to eq(spot.address)
        end
      end
    end

    describe "#category_background_color" do
      context "snapshot_category_idがある場合" do
        it "そのカテゴリの背景色クラスを返すこと" do
          category = create(:category, name: "観光地")
          schedule_spot = build(:schedule_spot, snapshot_category_id: category.id)
          expect(schedule_spot.category_background_color).to eq("bg-sky-100/60")
        end
      end

      context "snapshot_category_idがなく、spot.category_idがある場合" do
        it "spotのカテゴリの背景色クラスを返すこと" do
          category = create(:category, name: "グルメ")
          spot = create(:spot, category: category)
          schedule_spot = build(:schedule_spot, snapshot_category_id: nil, spot: spot)
          expect(schedule_spot.category_background_color).to eq("bg-red-100/60")
        end
      end

      context "どちらのcategory_idもない場合" do
        it "bg-whiteを返すこと" do
          schedule_spot = build(:schedule_spot, snapshot_category_id: nil, spot: nil)
          expect(schedule_spot.category_background_color).to eq("bg-white")
        end
      end

      context "category_idはあるがCategoryが見つからない場合" do
        it "bg-whiteを返すこと" do
          schedule_spot = build(:schedule_spot, snapshot_category_id: 99999)
          expect(schedule_spot.category_background_color).to eq("bg-white")
        end
      end
    end
  end

  describe 'acts_as_list（並び替え）' do
    let(:schedule_a) { create(:schedule) }
    let(:schedule_b) { create(:schedule) }

    context '同じしおり・同じ日内での並び順の場合' do
      let!(:spot1) { create(:schedule_spot, schedule: schedule_a, day_number: 1) }
      let!(:spot2) { create(:schedule_spot, schedule: schedule_a, day_number: 1) }
      let!(:spot3) { create(:schedule_spot, schedule: schedule_a, day_number: 1) }

      it 'global_positionが自動的に割り当てられること' do
        expect(spot1.global_position).to eq(1)
        expect(spot2.global_position).to eq(2)
        expect(spot3.global_position).to eq(3)
      end

      it 'スポットを削除すると後続のglobal_positionが繰り上がること' do
        spot2.destroy
        expect(spot3.reload.global_position).to eq(2)
      end
    end

    context '異なるしおり間でのglobal_positionの独立性' do
      let!(:spot_a1) { create(:schedule_spot, schedule: schedule_a, day_number: 1) }
      let!(:spot_a2) { create(:schedule_spot, schedule: schedule_a, day_number: 1) }
      let!(:spot_b1) { create(:schedule_spot, schedule: schedule_b, day_number: 1) }
      let!(:spot_b2) { create(:schedule_spot, schedule: schedule_b, day_number: 1) }

      it '各しおりで独立したglobal_positionを持つこと' do
        expect(spot_a1.global_position).to eq(1)
        expect(spot_a2.global_position).to eq(2)
        expect(spot_b1.global_position).to eq(1)
        expect(spot_b2.global_position).to eq(2)
      end

      it 'しおりAのスポットを削除してもしおりBには影響しないこと' do
        spot_a1.destroy
        expect(spot_a2.reload.global_position).to eq(1)
        expect(spot_b1.reload.global_position).to eq(1)
        expect(spot_b2.reload.global_position).to eq(2)
      end
    end

    context '異なる日にち間でのglobal_positionの独立性' do
      let!(:day1_spot1) { create(:schedule_spot, schedule: schedule_a, day_number: 1) }
      let!(:day1_spot2) { create(:schedule_spot, schedule: schedule_a, day_number: 1) }
      let!(:day2_spot1) { create(:schedule_spot, schedule: schedule_a, day_number: 2) }
      let!(:day2_spot2) { create(:schedule_spot, schedule: schedule_a, day_number: 2) }

      it '各日にちで独立したglobal_positionを持つこと' do
        expect(day1_spot1.global_position).to eq(1)
        expect(day1_spot2.global_position).to eq(2)
        expect(day2_spot1.global_position).to eq(1)
        expect(day2_spot2.global_position).to eq(2)
      end

      it '1日目のスポットを削除しても2日目には影響しないこと' do
        day1_spot1.destroy
        expect(day1_spot2.reload.global_position).to eq(1)
        expect(day2_spot1.reload.global_position).to eq(1)
        expect(day2_spot2.reload.global_position).to eq(2)
      end
    end

    context '並び替え機能' do
      let!(:spot1) { create(:schedule_spot, schedule: schedule_a, day_number: 1) }
      let!(:spot2) { create(:schedule_spot, schedule: schedule_a, day_number: 1) }
      let!(:spot3) { create(:schedule_spot, schedule: schedule_a, day_number: 1) }

      it 'move_higherで上に移動できること' do
        spot2.move_higher
        expect(spot1.reload.global_position).to eq(2)
        expect(spot2.reload.global_position).to eq(1)
        expect(spot3.reload.global_position).to eq(3)
      end

      it 'move_lowerで下に移動できること' do
        spot2.move_lower
        expect(spot1.reload.global_position).to eq(1)
        expect(spot2.reload.global_position).to eq(3)
        expect(spot3.reload.global_position).to eq(2)
      end

      it '最上位のスポットはmove_higherしても変わらないこと' do
        spot1.move_higher
        expect(spot1.reload.global_position).to eq(1)
        expect(spot2.reload.global_position).to eq(2)
        expect(spot3.reload.global_position).to eq(3)
      end

      it '最下位のスポットはmove_lowerしても変わらないこと' do
        spot3.move_lower
        expect(spot1.reload.global_position).to eq(1)
        expect(spot2.reload.global_position).to eq(2)
        expect(spot3.reload.global_position).to eq(3)
      end
    end

    context '日付を跨ぐ移動' do
      let!(:day1_spot1) { create(:schedule_spot, schedule: schedule_a, day_number: 1) }
      let!(:day1_spot2) { create(:schedule_spot, schedule: schedule_a, day_number: 1) }
      let!(:day1_spot3) { create(:schedule_spot, schedule: schedule_a, day_number: 1) }
      let!(:day2_spot1) { create(:schedule_spot, schedule: schedule_a, day_number: 2) }
      let!(:day2_spot2) { create(:schedule_spot, schedule: schedule_a, day_number: 2) }

      it 'day_numberを変更すると移動先のday内で新しいpositionが割り当てられること' do
        # 1日目のspot2を2日目に移動
        day1_spot2.update!(day_number: 2)

        # 移動先（2日目）では最後尾に追加される
        expect(day1_spot2.reload.global_position).to eq(3)

        # 元の1日目では後続のpositionが詰まる
        expect(day1_spot1.reload.global_position).to eq(1)
        expect(day1_spot3.reload.global_position).to eq(2)

        # 2日目の既存スポットは影響を受けない
        expect(day2_spot1.reload.global_position).to eq(1)
        expect(day2_spot2.reload.global_position).to eq(2)
      end
    end
  end
end
