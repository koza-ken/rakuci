require 'rails_helper'

RSpec.describe "Groups::Schedules::ItemLists", type: :request do
  let(:creator) { create(:user) }
  let(:group) { create(:group, creator: creator) }
  let(:member) { create(:group_membership, group: group).user }
  let!(:schedule) { create(:schedule, :for_group, schedulable: group) }

  before do
    sign_in member
  end

  describe "GET /groups/:group_id/schedule/item_list" do
    context "ログインしたグループメンバーの場合" do
      it "グループスケジュールの持ち物リストページが表示されること" do
        get group_schedule_item_list_path(group)
        expect(response).to have_http_status(:success)
      end

      it "item_list のアイテムを position の順で取得すること" do
        item_list = schedule.item_list
        item1 = create(:item, item_list: item_list, position: 1)
        item2 = create(:item, item_list: item_list, position: 2)
        item3 = create(:item, item_list: item_list, position: 3)

        get group_schedule_item_list_path(group)
        expect(response).to have_http_status(:success)
        # ビューに表示されていることを確認
        expect(response.body).to include(item1.name)
        expect(response.body).to include(item2.name)
        expect(response.body).to include(item3.name)
      end
    end

    context "ログインしていない場合" do
      before do
        sign_out member
      end

      it "ルートページにリダイレクトされること" do
        get group_schedule_item_list_path(group)
        expect(response).to redirect_to(root_path)
      end
    end

    context "グループのメンバーではない場合" do
      let(:non_member) { create(:user) }

      before do
        sign_in non_member
      end

      it "グループトップページにリダイレクトされること" do
        get group_schedule_item_list_path(group)
        expect(response).to redirect_to(groups_path)
      end
    end
  end

  describe "POST /groups/:group_id/schedule/item_list/items" do
    let(:item_list) { schedule.item_list }

    context "有効なパラメーターの場合" do
      it "グループスケジュール用のアイテムが作成されること" do
        expect {
          post group_schedule_item_list_items_path(group), params: {
            item: { name: "新しいアイテム" }
          }
        }.to change(Item, :count).by(1)

        expect(Item.last.item_list).to eq(item_list)
      end

      it "Turbo Streamレスポンスを返すこと" do
        post group_schedule_item_list_items_path(group), params: {
          item: { name: "新しいアイテム" }
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
        post group_schedule_item_list_items_path(group), params: {
          item: { name: "新しいアイテム" }
        }
        expect(response).to redirect_to(groups_path)
      end
    end
  end

  describe "PATCH /groups/:group_id/schedule/item_list/items/:id" do
    let(:item) { create(:item, item_list: schedule.item_list, name: "元のアイテム") }

    context "nameを更新する場合" do
      it "アイテムのnameが更新されること" do
        patch group_schedule_item_list_item_path(group, item), params: {
          item: { name: "更新されたアイテム" }
        }

        item.reload
        expect(item.name).to eq("更新されたアイテム")
      end
    end

    context "checkedを更新する場合" do
      it "アイテムのcheckedが更新されること" do
        patch group_schedule_item_list_item_path(group, item), params: {
          item: { checked: true }
        }, headers: { "Accept" => "application/json" }

        item.reload
        expect(item.checked).to be true
      end

      it "JSON レスポンスで :ok を返すこと" do
        patch group_schedule_item_list_item_path(group, item), params: {
          item: { checked: true }
        }, headers: { "Accept" => "application/json" }

        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "DELETE /groups/:group_id/schedule/item_list/items/:id" do
    let(:item) { create(:item, item_list: schedule.item_list) }

    it "アイテムが削除されること" do
      item_id = item.id
      expect {
        delete group_schedule_item_list_item_path(group, item)
      }.to change(Item, :count).by(-1)

      expect(Item.find_by(id: item_id)).to be_nil
    end

    it "Turbo Stream レスポンスを返すこと" do
      delete group_schedule_item_list_item_path(group, item), headers: { "Accept" => "text/vnd.turbo-stream.html" }
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include("text/vnd.turbo-stream.html")
    end
  end
end
