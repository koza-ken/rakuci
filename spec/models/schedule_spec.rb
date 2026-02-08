# == Schema Information
#
# Table name: schedules
#
#  id               :bigint           not null, primary key
#  end_date         :date
#  memo             :text
#  name             :string           not null
#  schedulable_type :string           not null
#  start_date       :date
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  schedulable_id   :bigint           not null
#
# Indexes
#
#  index_schedules_on_polymorphic  (schedulable_type,schedulable_id) UNIQUE WHERE ((schedulable_type)::text = 'Group'::text)
#
require "rails_helper"

RSpec.describe Schedule, type: :model do
  describe "バリデーション" do
    describe "name" do
      context "nameが存在しない場合" do
        it "保存に失敗すること" do
          schedule = build(:schedule, name: nil)
          expect(schedule).not_to be_valid
        end
      end

      context "文字数が50文字以下の場合" do
        it "保存に成功すること" do
          schedule = build(:schedule, name: "a" * 50)
          expect(schedule).to be_valid
        end
      end

      context "文字数が51文字以上の場合" do
        it "保存に失敗すること" do
          schedule = build(:schedule, name: "a" * 51)
          expect(schedule).not_to be_valid
        end
      end
    end

    describe "end_date" do
      context "start_dateとend_dateが両方空の場合" do
        it "保存に成功すること" do
          schedule = build(:schedule, start_date: nil, end_date: nil)
          expect(schedule).to be_valid
        end
      end

      context "start_dateがあり、end_dateが空の場合" do
        it "保存に成功すること" do
          schedule = build(:schedule, start_date: Date.current, end_date: nil)
          expect(schedule).to be_valid
        end
      end

      context "end_dateがstart_dateより後の場合" do
        it "保存に成功すること" do
          schedule = build(:schedule, start_date: Date.current, end_date: Date.current + 1.day)
          expect(schedule).to be_valid
        end
      end

      context "end_dateがstart_dateと同じ場合" do
        it "保存に成功すること" do
          schedule = build(:schedule, start_date: Date.current, end_date: Date.current)
          expect(schedule).to be_valid
        end
      end

      context "end_dateがstart_dateより前の場合" do
        it "保存に失敗すること" do
          schedule = build(:schedule, start_date: Date.current, end_date: Date.current - 1.day)
          expect(schedule).not_to be_valid
        end
      end
    end

    describe "only_one_schedule_per_group" do
      context "ユーザーが複数のしおりを作成する場合" do
        it "保存に成功すること" do
          user = create(:user)
          schedule1 = create(:schedule, :for_user, schedulable: user)
          schedule2 = build(:schedule, :for_user, schedulable: user)
          expect(schedule2).to be_valid
        end
      end

      context "グループが初めてのしおりを作成する場合" do
        it "保存に成功すること" do
          group = create(:group)
          schedule = build(:schedule, :for_group, schedulable: group)
          expect(schedule).to be_valid
        end
      end

      context "グループが既にしおりを持っている場合" do
        it "保存に失敗すること" do
          group = create(:group)
          schedule1 = create(:schedule, :for_group, schedulable: group)
          schedule2 = build(:schedule, :for_group, schedulable: group)
          expect(schedule2).not_to be_valid
        end
      end
    end
  end

  describe "メソッド" do
    describe "#schedule_type" do
      context "個人のしおりの場合" do
        it "personalを返すこと" do
          user = create(:user)
          schedule = create(:schedule, :for_user, schedulable: user)

          expect(schedule.schedule_type).to eq(:personal)
        end
      end

      context "グループのしおりの場合" do
        it "groupを返すこと" do
          group = create(:group)
          schedule = create(:schedule, :for_group, schedulable: group)

          expect(schedule.schedule_type).to eq(:group)
        end
      end
    end

    describe "#group" do
      context "グループのしおりの場合" do
        it "グループオブジェクトを返すこと" do
          group = create(:group)
          schedule = create(:schedule, :for_group, schedulable: group)

          expect(schedule.group).to eq(group)
        end
      end

      context "個人のしおりの場合" do
        it "nilを返すこと" do
          user = create(:user)
          schedule = create(:schedule, :for_user, schedulable: user)

          expect(schedule.group).to be_nil
        end
      end
    end

    describe "#days" do
      context "start_dateとend_dateが両方空の場合" do
        it "1を返すこと" do
          schedule = build(:schedule, start_date: nil, end_date: nil)

          expect(schedule.days).to eq(1)
        end
      end

      context "start_dateが7日間、end_dateがnilの場合" do
        it "1を返すこと" do
          schedule = build(:schedule, start_date: Date.current, end_date: nil)

          expect(schedule.days).to eq(1)
        end
      end

      context "start_dateとend_dateが同じ日の場合" do
        it "1を返すこと" do
          schedule = build(:schedule, start_date: Date.current, end_date: Date.current)

          expect(schedule.days).to eq(1)
        end
      end

      context "start_dateとend_dateが7日間離れている場合" do
        it "8を返すこと" do
          start_date = Date.current
          end_date = start_date + 7.days
          schedule = build(:schedule, start_date: start_date, end_date: end_date)

          expect(schedule.days).to eq(8)
        end
      end
    end

    describe "#formatted_date_for_day" do
      context "start_dateがnilの場合" do
        it "nilを返すこと" do
          schedule = build(:schedule, start_date: nil)

          expect(schedule.formatted_date_for_day(1)).to be_nil
        end
      end

      context "day_numberが1の場合" do
        it "start_dateの日付をフォーマット付きで返すこと" do
          start_date = Date.new(2025, 1, 1)
          schedule = build(:schedule, start_date: start_date)

          result = schedule.formatted_date_for_day(1)
          expect(result).to include("1")
          expect(result).to include("（")
        end
      end

      context "day_numberが3の場合" do
        it "3日後の日付をフォーマット付きで返すこと" do
          start_date = Date.new(2025, 1, 1)
          schedule = build(:schedule, start_date: start_date)

          result = schedule.formatted_date_for_day(3)
          # start_date + (3 - 1) = start_date + 2 = 2025-01-03
          expect(result).to include("3")
          expect(result).to include("（")
        end
      end
    end

    describe "#formatted_date_range" do
      context "start_dateとend_dateが両方nilの場合" do
        it "nilを返すこと" do
          schedule = build(:schedule, start_date: nil, end_date: nil)

          expect(schedule.formatted_date_range).to be_nil
        end
      end

      context "start_dateがあり、end_dateがnilの場合" do
        it "nilを返すこと" do
          schedule = build(:schedule, start_date: Date.current, end_date: nil)

          expect(schedule.formatted_date_range).to be_nil
        end
      end

      context "start_dateとend_dateが両方ある場合" do
        it "開始日～終了日を曜日付きでフォーマットして返すこと" do
          start_date = Date.new(2025, 1, 15)  # 水曜日
          end_date = Date.new(2025, 1, 20)    # 月曜日
          schedule = build(:schedule, start_date: start_date, end_date: end_date)

          result = schedule.formatted_date_range
          expect(result).to include("2025/01/15")
          expect(result).to include("2025/01/20")
          expect(result).to include("（")
          expect(result).to include("～")
        end
      end
    end
  end
end
