require 'rails_helper'

RSpec.describe "Groups::Schedules::PackingLists", type: :request do
  let(:creator) { create(:user) }
  let(:group) { create(:group, creator: creator) }
  let(:member) { create(:group_membership, group: group).user }
  let!(:schedule) { create(:schedule, :for_group, schedulable: group) }

  before do
    sign_in member
  end

  describe "GET /groups/:group_id/schedule/packing_list" do
    context "ログインしたグループメンバーの場合" do
      it "グループスケジュールの持ち物リストページが表示されること" do
        get group_schedule_packing_list_path(group)
        expect(response).to have_http_status(:success)
      end

      it "packing_list のアイテムを position の順で取得すること" do
        packing_list = schedule.packing_list
        packing_item1 = create(:packing_item, packing_list: packing_list, position: 1)
        packing_item2 = create(:packing_item, packing_list: packing_list, position: 2)
        packing_item3 = create(:packing_item, packing_list: packing_list, position: 3)

        get group_schedule_packing_list_path(group)
        expect(response).to have_http_status(:success)
        # ビューに表示されていることを確認
        expect(response.body).to include(packing_item1.name)
        expect(response.body).to include(packing_item2.name)
        expect(response.body).to include(packing_item3.name)
      end
    end

    context "ログインしていない場合" do
      before do
        sign_out member
      end

      it "ルートページにリダイレクトされること" do
        get group_schedule_packing_list_path(group)
        expect(response).to redirect_to(root_path)
      end
    end

    context "グループのメンバーではない場合" do
      let(:non_member) { create(:user) }

      before do
        sign_in non_member
      end

      it "グループトップページにリダイレクトされること" do
        get group_schedule_packing_list_path(group)
        expect(response).to redirect_to(groups_path)
      end
    end
  end

  describe "POST /groups/:group_id/schedule/packing_list/packing_items" do
    let(:packing_list) { schedule.packing_list }

    context "有効なパラメーターの場合" do
      it "グループスケジュール用のアイテムが作成されること" do
        expect {
          post group_schedule_packing_list_items_path(group), params: {
            packing_item: { name: "新しいアイテム" }
          }
        }.to change(PackingItem, :count).by(1)

        expect(PackingItem.last.packing_list).to eq(packing_list)
      end

      it "Turbo Streamレスポンスを返すこと" do
        post group_schedule_packing_list_items_path(group), params: {
          packing_item: { name: "新しいアイテム" }
        }, headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response).to have_http_status(:success)
        expect(response.content_type).to include("text/vnd.turbo-stream.html")
      end
    end

    context "メンバーではない場合" do
      let(:non_member) { create(:user) }

      before do
        sign_in non_member
      end

      it "リダイレクトされること" do
        post group_schedule_packing_list_items_path(group), params: {
          packing_item: { name: "新しいアイテム" }
        }
        expect(response).to redirect_to(groups_path)
      end
    end
  end

  describe "PATCH /groups/:group_id/schedule/packing_list/packing_items/:id" do
    let(:packing_item) { create(:packing_item, packing_list: schedule.packing_list, name: "元のアイテム") }

    context "nameを更新する場合" do
      it "アイテムのnameが更新されること" do
        patch group_schedule_packing_list_item_path(group, packing_item), params: {
          packing_item: { name: "更新されたアイテム" }
        }

        packing_item.reload
        expect(packing_item.name).to eq("更新されたアイテム")
      end
    end

    context "checkedを更新する場合" do
      it "アイテムのcheckedが更新されること" do
        patch group_schedule_packing_list_item_path(group, packing_item), params: {
          packing_item: { checked: true }
        }, headers: { "Accept" => "application/json" }

        packing_item.reload
        expect(packing_item.checked).to be true
      end

      it "JSON レスポンスで :ok を返すこと" do
        patch group_schedule_packing_list_item_path(group, packing_item), params: {
          packing_item: { checked: true }
        }, headers: { "Accept" => "application/json" }

        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "DELETE /groups/:group_id/schedule/packing_list/packing_items/:id" do
    let(:packing_item) { create(:packing_item, packing_list: schedule.packing_list) }

    it "アイテムが削除されること" do
      packing_item_id = packing_item.id
      expect {
        delete group_schedule_packing_list_item_path(group, packing_item)
      }.to change(PackingItem, :count).by(-1)

      expect(PackingItem.find_by(id: packing_item_id)).to be_nil
    end

    it "Turbo Stream レスポンスを返すこと" do
      delete group_schedule_packing_list_item_path(group, packing_item), headers: { "Accept" => "text/vnd.turbo-stream.html" }
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include("text/vnd.turbo-stream.html")
    end
  end
end
