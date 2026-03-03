require 'rails_helper'

RSpec.describe "Users::Schedules::PackingLists", type: :request do
  let(:user) { create(:user) }
  let(:schedule) { create(:schedule, schedulable: user) }

  before do
    sign_in user
  end

  describe "GET /schedules/:schedule_id/packing_list" do
    context "ログインしている場合" do
      it "スケジュールの持ち物リストページが表示されること" do
        get schedule_packing_list_path(schedule)
        expect(response).to have_http_status(:success)
      end

      it "packing_list のアイテムを position の順で取得すること" do
        packing_list = schedule.packing_list
        packing_item1 = create(:packing_item, packing_list: packing_list, position: 1)
        packing_item2 = create(:packing_item, packing_list: packing_list, position: 2)
        packing_item3 = create(:packing_item, packing_list: packing_list, position: 3)

        get schedule_packing_list_path(schedule)
        expect(response).to have_http_status(:success)
        # ビューに表示されていることを確認
        expect(response.body).to include(packing_item1.name)
        expect(response.body).to include(packing_item2.name)
        expect(response.body).to include(packing_item3.name)
      end
    end

    context "ログインしていない場合" do
      before do
        sign_out user
      end

      it "ログインページにリダイレクトされること" do
        get schedule_packing_list_path(schedule)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "他のユーザーのスケジュールの場合" do
      let(:other_user) { create(:user) }
      let(:other_schedule) { create(:schedule, schedulable: other_user) }

      it "404 エラーが返されること" do
        get schedule_packing_list_path(other_schedule)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "POST /schedules/:schedule_id/packing_list/packing_items" do
    let(:packing_list) { schedule.packing_list }

    context "有効なパラメーターの場合" do
      it "スケジュール用のアイテムが作成されること" do
        expect {
          post schedule_packing_list_items_path(schedule), params: {
            packing_item: { name: "新しいアイテム" }
          }
        }.to change(PackingItem, :count).by(1)

        expect(PackingItem.last.packing_list).to eq(packing_list)
      end

      it "Turbo Streamレスポンスを返すこと" do
        post schedule_packing_list_items_path(schedule), params: {
          packing_item: { name: "新しいアイテム" }
        }, headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response).to have_http_status(:success)
        expect(response.content_type).to include("text/vnd.turbo-stream.html")
      end
    end
  end

  describe "PATCH /schedules/:schedule_id/packing_list/packing_items/:id" do
    let(:packing_item) { create(:packing_item, packing_list: schedule.packing_list, name: "元のアイテム") }

    context "nameを更新する場合" do
      it "アイテムのnameが更新されること" do
        patch schedule_packing_list_item_path(schedule, packing_item), params: {
          packing_item: { name: "更新されたアイテム" }
        }

        packing_item.reload
        expect(packing_item.name).to eq("更新されたアイテム")
      end
    end

    context "checkedを更新する場合" do
      it "アイテムのcheckedが更新されること" do
        patch schedule_packing_list_item_path(schedule, packing_item), params: {
          packing_item: { checked: true }
        }, headers: { "Accept" => "application/json" }

        packing_item.reload
        expect(packing_item.checked).to be true
      end

      it "JSON レスポンスで :ok を返すこと" do
        patch schedule_packing_list_item_path(schedule, packing_item), params: {
          packing_item: { checked: true }
        }, headers: { "Accept" => "application/json" }

        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "DELETE /schedules/:schedule_id/packing_list/packing_items/:id" do
    let(:packing_item) { create(:packing_item, packing_list: schedule.packing_list) }

    it "アイテムが削除されること" do
      packing_item_id = packing_item.id
      expect {
        delete schedule_packing_list_item_path(schedule, packing_item)
      }.to change(PackingItem, :count).by(-1)

      expect(PackingItem.find_by(id: packing_item_id)).to be_nil
    end

    it "Turbo Stream レスポンスを返すこと" do
      delete schedule_packing_list_item_path(schedule, packing_item), headers: { "Accept" => "text/vnd.turbo-stream.html" }
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include("text/vnd.turbo-stream.html")
    end
  end
end
