require 'rails_helper'

RSpec.describe "Users::Schedules::ItemLists", type: :request do
  let(:user) { create(:user) }
  let(:schedule) { create(:schedule, schedulable: user) }

  before do
    sign_in user
  end

  describe "GET /schedules/:schedule_id/item_list" do
    context "ログインしている場合" do
      it "スケジュールの持ち物リストページが表示されること" do
        get schedule_item_list_path(schedule)
        expect(response).to have_http_status(:success)
      end

      it "item_list のアイテムを position の順で取得すること" do
        item_list = schedule.item_list
        item1 = create(:item, item_list: item_list, position: 1)
        item2 = create(:item, item_list: item_list, position: 2)
        item3 = create(:item, item_list: item_list, position: 3)

        get schedule_item_list_path(schedule)
        expect(response).to have_http_status(:success)
        # ビューに表示されていることを確認
        expect(response.body).to include(item1.name)
        expect(response.body).to include(item2.name)
        expect(response.body).to include(item3.name)
      end
    end

    context "ログインしていない場合" do
      before do
        sign_out user
      end

      it "ログインページにリダイレクトされること" do
        get schedule_item_list_path(schedule)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "他のユーザーのスケジュールの場合" do
      let(:other_user) { create(:user) }
      let(:other_schedule) { create(:schedule, schedulable: other_user) }

      it "404 エラーが返されること" do
        get schedule_item_list_path(other_schedule)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "POST /schedules/:schedule_id/item_list/items" do
    let(:item_list) { schedule.item_list }

    context "有効なパラメーターの場合" do
      it "スケジュール用のアイテムが作成されること" do
        expect {
          post schedule_item_list_items_path(schedule), params: {
            item: { name: "新しいアイテム" }
          }
        }.to change(Item, :count).by(1)

        expect(Item.last.item_list).to eq(item_list)
      end

      it "Turbo Streamレスポンスを返すこと" do
        post schedule_item_list_items_path(schedule), params: {
          item: { name: "新しいアイテム" }
        }, headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response).to have_http_status(:success)
        expect(response.content_type).to include("text/vnd.turbo-stream.html")
      end
    end
  end

  describe "PATCH /schedules/:schedule_id/item_list/items/:id" do
    let(:item) { create(:item, item_list: schedule.item_list, name: "元のアイテム") }

    context "nameを更新する場合" do
      it "アイテムのnameが更新されること" do
        patch schedule_item_list_item_path(schedule, item), params: {
          item: { name: "更新されたアイテム" }
        }

        item.reload
        expect(item.name).to eq("更新されたアイテム")
      end
    end

    context "checkedを更新する場合" do
      it "アイテムのcheckedが更新されること" do
        patch schedule_item_list_item_path(schedule, item), params: {
          item: { checked: true }
        }, headers: { "Accept" => "application/json" }

        item.reload
        expect(item.checked).to be true
      end

      it "JSON レスポンスで :ok を返すこと" do
        patch schedule_item_list_item_path(schedule, item), params: {
          item: { checked: true }
        }, headers: { "Accept" => "application/json" }

        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "DELETE /schedules/:schedule_id/item_list/items/:id" do
    let(:item) { create(:item, item_list: schedule.item_list) }

    it "アイテムが削除されること" do
      item_id = item.id
      expect {
        delete schedule_item_list_item_path(schedule, item)
      }.to change(Item, :count).by(-1)

      expect(Item.find_by(id: item_id)).to be_nil
    end

    it "Turbo Stream レスポンスを返すこと" do
      delete schedule_item_list_item_path(schedule, item), headers: { "Accept" => "text/vnd.turbo-stream.html" }
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include("text/vnd.turbo-stream.html")
    end
  end
end
