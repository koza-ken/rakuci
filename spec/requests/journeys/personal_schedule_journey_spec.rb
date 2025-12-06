require "rails_helper"

RSpec.describe "個人ユーザーのしおり作成フロー", type: :request do
  let(:user) { create(:user) }
  let(:category) { create(:category) }

  before do
    sign_in user
  end

  describe "カード作成からしおり完成までの一連の流れ" do
    it "正常に進行すること" do
      # カード作成
      post "/cards", params: {
        card: {
          name: "東京観光",
          memo: "東京での観光地を集めたカード"
        }
      }
      expect(response).to redirect_to(/\/cards/)
      card = Card.last
      expect(card.name).to eq("東京観光")
      expect(card.user_id).to eq(user.id)

      # スポット追加
      post "/cards/#{card.id}/spots", params: {
        spot: {
          name: "スカイツリー",
          address: "東京都墨田区押花2-1-1",
          category_id: category.id
        }
      }
      expect(response).to redirect_to(/\/cards/)
      spot = Spot.last
      expect(spot.name).to eq("スカイツリー")
      expect(spot.card_id).to eq(card.id)

      # 個人用しおり作成
      post "/schedules", params: {
        schedule: {
          name: "東京旅行",
          start_date: Date.current,
          end_date: Date.current + 3.days
        }
      }
      expect(response).to redirect_to(/\/schedules/)
      schedule = Schedule.last
      expect(schedule.name).to eq("東京旅行")
      expect(schedule.schedule_type).to eq(:personal)

      # スポットをしおりに追加
      post "/schedules/#{schedule.id}/schedule_spots", params: {
        schedule_spot: {
          day_number: 1,
          global_position: 1
        },
        card_id: card.id,
        schedule_id: schedule.id,
        spot_id: spot.id
      }
      expect(response).to redirect_to(/\/cards/)

      # スケジュールスポットが作成されたことを確認
      schedule.reload
      expect(schedule.schedule_spots.count).to eq(1)
      schedule_spot = schedule.schedule_spots.first
      expect(schedule_spot.spot_id).to eq(spot.id)
      expect(schedule_spot.day_number).to eq(1)
    end
  end

  describe "複数のスポットをしおりに追加" do
    it "複数のスポットが正常に追加できること" do
      card = create(:card, user: user)
      spot1 = create(:spot, card: card, name: "スカイツリー")
      spot2 = create(:spot, card: card, name: "浅草寺")
      spot3 = create(:spot, card: card, name: "スカイツリーの隣")

      schedule = create(:schedule, :for_user, schedulable: user)

      # 複数スポットを追加
      post "/schedules/#{schedule.id}/schedule_spots", params: {
        schedule_spot: {},
        card_id: card.id,
        schedule_id: schedule.id,
        spot_id: spot1.id
      }

      post "/schedules/#{schedule.id}/schedule_spots", params: {
        schedule_spot: {},
        card_id: card.id,
        schedule_id: schedule.id,
        spot_id: spot2.id
      }

      post "/schedules/#{schedule.id}/schedule_spots", params: {
        schedule_spot: {},
        card_id: card.id,
        schedule_id: schedule.id,
        spot_id: spot3.id
      }

      schedule.reload
      expect(schedule.schedule_spots.count).to eq(3)
      expect(schedule.schedule_spots.map(&:spot_id)).to contain_exactly(spot1.id, spot2.id, spot3.id)
    end
  end

  describe "しおりの編集・削除" do
    it "しおりを編集できること" do
      schedule = create(:schedule, :for_user, schedulable: user, name: "旧タイトル")

      patch "/schedules/#{schedule.id}", params: {
        schedule: { name: "新タイトル" }
      }
      expect(response).to redirect_to(/\/schedules/)

      schedule.reload
      expect(schedule.name).to eq("新タイトル")
    end

    it "しおりを削除できること" do
      schedule = create(:schedule, :for_user, schedulable: user)
      schedule_id = schedule.id

      delete "/schedules/#{schedule.id}"
      expect(response).to redirect_to(/\/schedules/)

      expect(Schedule.find_by(id: schedule_id)).to be_nil
    end
  end
end
