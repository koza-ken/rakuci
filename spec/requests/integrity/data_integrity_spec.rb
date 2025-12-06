require "rails_helper"

RSpec.describe "データ保全性チェック", type: :request do
  let(:user) { create(:user) }
  let(:category) { create(:category) }

  describe "個人カード削除時のカスケード削除" do
    it "個人カードを削除すると関連データがすべて削除されること" do
      card = create(:card, user: user)
      spot = create(:spot, card: card)
      schedule = create(:schedule, :for_user, schedulable: user)
      schedule_spot = create(:schedule_spot, schedule: schedule, spot: spot)

      sign_in user

      card_id = card.id
      spot_id = spot.id

      delete "/cards/#{card.id}"
      expect(response).to redirect_to(/\/cards/)

      expect(Card.find_by(id: card_id)).to be_nil
      expect(Spot.find_by(id: spot_id)).to be_nil
      expect(ScheduleSpot.find_by(spot_id: spot_id)).to be_nil
    end
  end

  describe "スケジュール削除時のカスケード削除" do
    it "スケジュールを削除すると関連のスケジュールスポットがすべて削除されること" do
      card = create(:card, user: user)
      spot1 = create(:spot, card: card)
      spot2 = create(:spot, card: card)
      schedule = create(:schedule, :for_user, schedulable: user)
      schedule_spot1 = create(:schedule_spot, schedule: schedule, spot: spot1)
      schedule_spot2 = create(:schedule_spot, schedule: schedule, spot: spot2)

      sign_in user

      schedule_id = schedule.id
      schedule_spot1_id = schedule_spot1.id
      schedule_spot2_id = schedule_spot2.id

      delete "/schedules/#{schedule.id}"
      expect(response).to redirect_to(/\/schedules/)

      expect(Schedule.find_by(id: schedule_id)).to be_nil
      expect(ScheduleSpot.find_by(id: schedule_spot1_id)).to be_nil
      expect(ScheduleSpot.find_by(id: schedule_spot2_id)).to be_nil
    end
  end

  describe "グループ削除時のカスケード削除" do
    it "グループを削除すると関連データがすべて削除されること" do
      group = create(:group, creator: user)
      membership = create(:group_membership, user: user, group: group, group_nickname: "userのニックネーム")
      card = create(:card, :for_group, group: group)
      spot = create(:spot, card: card)
      schedule = create(:schedule, :for_group, schedulable: group)
      schedule_spot = create(:schedule_spot, schedule: schedule, spot: spot)

      sign_in user

      group_id = group.id
      card_id = card.id
      spot_id = spot.id

      delete "/groups/#{group.id}"
      expect(response).to redirect_to(/\/groups/)

      expect(Group.find_by(id: group_id)).to be_nil
      expect(Card.find_by(id: card_id)).to be_nil
      expect(Spot.find_by(id: spot_id)).to be_nil
    end
  end
end
